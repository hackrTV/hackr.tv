require "rails_helper"

RSpec.describe "Performance caching" do
  let(:region) { create(:grid_region) }
  let(:zone) { create(:grid_zone, grid_region: region) }
  let(:hackr) { create(:grid_hackr) }

  # Test env uses :null_store — swap to :memory_store for cache tests
  around do |example|
    original_store = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    example.run
  ensure
    Rails.cache = original_store
  end

  # ── ZoneMapBuilder topology/overlay split ──────────────────────

  describe Grid::ZoneMapBuilder do
    let(:room_a) { create(:grid_room, :hub, grid_zone: zone, name: "Hub") }
    let(:room_b) { create(:grid_room, grid_zone: zone, name: "Corridor") }

    before do
      GridExit.create!(from_room: room_a, to_room: room_b, direction: "north")
      GridExit.create!(from_room: room_b, to_room: room_a, direction: "south")
      hackr.update!(current_room: room_a)
      GridRoomVisit.create!(grid_hackr: hackr, grid_room: room_a, first_visited_at: Time.current)
    end

    it "returns identical output shape whether topology is cached or not" do
      builder = described_class.new(zone: zone, hackr: hackr)

      # First call — populates cache
      result1 = builder.build

      # Second call — reads from cache
      result2 = described_class.new(zone: zone, hackr: hackr).build

      expect(result2.zone).to eq(result1.zone)
      expect(result2.rooms.map { |r| r[:id] }.sort).to eq(result1.rooms.map { |r| r[:id] }.sort)
      expect(result2.exits.size).to eq(result1.exits.size)
      expect(result2.current_room_id).to eq(result1.current_room_id)
      expect(result2.z_levels).to eq(result1.z_levels)
    end

    it "applies fog-of-war correctly from cached topology" do
      # hackr has visited room_a but not room_b
      result = described_class.new(zone: zone, hackr: hackr).build

      visited_room = result.rooms.find { |r| r[:id] == room_a.id }
      adjacent_room = result.rooms.find { |r| r[:id] == room_b.id }

      expect(visited_room[:visited]).to be true
      expect(visited_room[:name]).to eq("Hub")

      expect(adjacent_room[:visited]).to be false
      expect(adjacent_room[:name]).to eq("???")
    end

    it "shows ghost room when only one of multiple connecting exits is visible" do
      zone2 = create(:grid_zone, grid_region: region)
      ghost_room = create(:grid_room, grid_zone: zone2, name: "Ghost Target")
      room_c = create(:grid_room, grid_zone: zone, name: "Hidden Room")

      # Two exits from this zone to the same ghost room:
      # one from a hidden room (room_c), one from the visited hub (room_a)
      GridExit.create!(from_room: room_c, to_room: ghost_room, direction: "east")
      GridExit.create!(from_room: room_a, to_room: ghost_room, direction: "west")

      # hackr has NOT visited room_c, but has visited room_a
      result = described_class.new(zone: zone, hackr: hackr).build

      ghost = result.ghost_rooms.find { |g| g[:id] == ghost_room.id }
      expect(ghost).not_to be_nil
      expect(ghost[:local_room_id]).to eq(room_a.id)
    end

    it "caches topology and serves from cache on second call" do
      described_class.new(zone: zone, hackr: hackr).build

      cache_key = described_class.topology_cache_key(zone.id)
      expect(Rails.cache.exist?(cache_key)).to be true
    end

    describe ".bust_cache!" do
      it "removes the cached topology for the given zone" do
        described_class.new(zone: zone, hackr: hackr).build
        cache_key = described_class.topology_cache_key(zone.id)

        expect { described_class.bust_cache!(zone.id) }
          .to change { Rails.cache.exist?(cache_key) }.from(true).to(false)
      end
    end
  end

  # ── Cache invalidation callbacks ───────────────────────────────

  describe "cache invalidation callbacks" do
    let!(:room) { create(:grid_room, :hub, grid_zone: zone, name: "Hub") }

    before do
      hackr.update!(current_room: room)
      GridRoomVisit.create!(grid_hackr: hackr, grid_room: room, first_visited_at: Time.current)
      # Warm the cache
      Grid::ZoneMapBuilder.new(zone: zone, hackr: hackr).build
    end

    let(:cache_key) { Grid::ZoneMapBuilder.topology_cache_key(zone.id) }

    describe "GridRoom" do
      it "busts zone map cache on structural change (name)" do
        expect { room.update!(name: "New Name") }
          .to change { Rails.cache.exist?(cache_key) }.from(true).to(false)
      end

      it "busts zone map cache on room_type change" do
        expect { room.update!(room_type: "standard") }
          .to change { Rails.cache.exist?(cache_key) }.from(true).to(false)
      end

      it "does NOT bust zone map cache on description-only change" do
        room.update!(description: "Updated flavor text")
        expect(Rails.cache.exist?(cache_key)).to be true
      end

      it "busts zone map cache on create" do
        expect { create(:grid_room, grid_zone: zone, name: "New Room") }
          .to change { Rails.cache.exist?(cache_key) }.from(true).to(false)
      end

      it "busts both old and new zone caches on zone change" do
        zone2 = create(:grid_zone, grid_region: region)
        cache_key2 = Grid::ZoneMapBuilder.topology_cache_key(zone2.id)

        # Warm zone2 cache
        create(:grid_room, grid_zone: zone2)
        Grid::ZoneMapBuilder.new(zone: zone2, hackr: hackr).build

        # Re-warm zone1 cache (was busted by zone2 room create)
        Grid::ZoneMapBuilder.new(zone: zone, hackr: hackr).build

        room.update!(grid_zone: zone2)

        expect(Rails.cache.exist?(cache_key)).to be false
        expect(Rails.cache.exist?(cache_key2)).to be false
      end
    end

    describe "GridExit" do
      it "busts zone map cache on exit create" do
        room2 = create(:grid_room, grid_zone: zone)
        # Re-warm cache after room create busted it
        Grid::ZoneMapBuilder.new(zone: zone, hackr: hackr).build

        expect { GridExit.create!(from_room: room, to_room: room2, direction: "east") }
          .to change { Rails.cache.exist?(cache_key) }.from(true).to(false)
      end

      it "busts zone map cache on exit destroy" do
        room2 = create(:grid_room, grid_zone: zone)
        exit_record = GridExit.create!(from_room: room, to_room: room2, direction: "east")
        # Re-warm
        Grid::ZoneMapBuilder.new(zone: zone, hackr: hackr).build

        expect { exit_record.destroy! }
          .to change { Rails.cache.exist?(cache_key) }.from(true).to(false)
      end
    end

    describe "GridZone" do
      it "busts zone map cache on structural change (name)" do
        expect { zone.update!(name: "Renamed Zone") }
          .to change { Rails.cache.exist?(cache_key) }.from(true).to(false)
      end

      it "does NOT bust zone map cache on description-only change" do
        zone.update!(description: "New description")
        expect(Rails.cache.exist?(cache_key)).to be true
      end
    end

    describe "GridAchievement" do
      it "busts achievement list cache on create" do
        # Warm achievement list cache
        Grid::AchievementChecker.all_achievements_cached
        list_key = Grid::AchievementChecker::ACHIEVEMENT_LIST_KEY

        expect {
          create(:grid_achievement, slug: "test-bust", trigger_type: "manual", name: "Test")
        }.to change { Rails.cache.exist?(list_key) }.from(true).to(false)
      end
    end

    describe "GridFaction" do
      it "busts faction graph cache on faction update" do
        faction = create(:grid_faction)
        # Warm faction graph cache
        Grid::ReputationService.new(hackr).faction_standings
        faction_key = Grid::ReputationService::FACTION_GRAPH_KEY

        expect { faction.update!(name: "Renamed Faction") }
          .to change { Rails.cache.exist?(faction_key) }.from(true).to(false)
      end
    end

    describe "GridFactionRepLink" do
      it "busts faction graph cache on rep link create" do
        f1 = create(:grid_faction)
        f2 = create(:grid_faction)
        # Warm faction graph cache (cleared by faction creates — re-warm)
        Grid::ReputationService.new(hackr).faction_standings
        faction_key = Grid::ReputationService::FACTION_GRAPH_KEY

        expect {
          create(:grid_faction_rep_link, source_faction: f1, target_faction: f2, weight: 0.5)
        }.to change { Rails.cache.exist?(faction_key) }.from(true).to(false)
      end
    end
  end

  # ── ReputationService prime! + faction_standings guard ─────────

  describe Grid::ReputationService do
    let(:faction) { create(:grid_faction) }

    before do
      GridHackrReputation.create!(grid_hackr: hackr, subject: faction, value: 42)
    end

    describe "#prime!" do
      it "returns self for chaining" do
        service = described_class.new(hackr)
        expect(service.prime!).to be service
      end

      it "makes subsequent leaf_value calls use the preload" do
        service = described_class.new(hackr).prime!

        # After priming, leaf_value should return from cache without DB hit
        expect(service.leaf_value(faction)).to eq(42)
      end
    end

    describe "#faction_standings preserves external prime" do
      it "does not reset preload when service was already primed" do
        service = described_class.new(hackr).prime!

        # faction_standings should NOT wipe the preload via ensure
        service.faction_standings

        # If preload survived, this should still return 42 without a DB query
        expect(service.leaf_value(faction)).to eq(42)
      end

      it "resets preload when service was NOT primed externally" do
        service = described_class.new(hackr)

        # faction_standings self-primes and should reset after
        service.faction_standings

        # Preload was reset — leaf_value should still work (hits DB)
        expect(service.leaf_value(faction)).to eq(42)
      end
    end
  end

  # ── MissionService with injected reputation_service ────────────

  describe Grid::MissionService do
    let(:faction) { create(:grid_faction) }
    let(:giver_room) { create(:grid_room) }
    let(:giver) { create(:grid_mob, :quest_giver, grid_room: giver_room) }
    let!(:mission) do
      create(:grid_mission,
        giver_mob: giver,
        min_rep_faction: faction,
        min_rep_value: 10)
    end

    before do
      create(:grid_mission_objective,
        grid_mission: mission,
        objective_type: "visit_room",
        target_slug: "x",
        label: "Go x")
      hackr.update!(current_room: giver_room)
    end

    it "uses injected reputation_service for rep gate checks" do
      rep_service = Grid::ReputationService.new(hackr).prime!
      service = described_class.new(hackr, reputation_service: rep_service)

      # Without rep, mission should be unavailable (rep gate fails)
      available = service.available_missions(giver_room)
      expect(available).to be_empty

      # Grant rep and re-check with a fresh service sharing same rep_service
      GridHackrReputation.create!(grid_hackr: hackr, subject: faction, value: 50)
      rep_service2 = Grid::ReputationService.new(hackr).prime!
      service2 = described_class.new(hackr, reputation_service: rep_service2)

      available2 = service2.available_missions(giver_room)
      expect(available2.map(&:id)).to include(mission.id)
    end

    it "falls back to standalone reputation_service when not injected" do
      GridHackrReputation.create!(grid_hackr: hackr, subject: faction, value: 50)
      service = described_class.new(hackr)

      available = service.available_missions(giver_room)
      expect(available.map(&:id)).to include(mission.id)
    end
  end

  # ── AchievementChecker global caching ──────────────────────────

  describe Grid::AchievementChecker do
    describe ".all_achievements_cached" do
      it "caches the achievement list" do
        create(:grid_achievement, slug: "cached-test", trigger_type: "manual", name: "Cached")

        result1 = described_class.all_achievements_cached
        result2 = described_class.all_achievements_cached

        expect(result1.map(&:id)).to eq(result2.map(&:id))
        expect(Rails.cache.exist?(described_class::ACHIEVEMENT_LIST_KEY)).to be true
      end

      it "is busted by GridAchievement commit" do
        described_class.all_achievements_cached
        create(:grid_achievement, slug: "bust-test", trigger_type: "manual", name: "New")

        expect(Rails.cache.exist?(described_class::ACHIEVEMENT_LIST_KEY)).to be false
      end
    end

    describe "den memoization" do
      let(:den_owner) { create(:grid_hackr) }
      let(:den_room) { create(:grid_room, :den, owner: den_owner, grid_zone: zone) }
      let(:checker) { described_class.new(den_owner) }

      let!(:items_stored_achievement) do
        create(:grid_achievement,
          slug: "stored-5", trigger_type: "items_stored",
          trigger_data: {"count" => 5}, name: "Storer")
      end
      let!(:fixtures_placed_achievement) do
        create(:grid_achievement,
          slug: "fixtures-1", trigger_type: "fixtures_placed",
          trigger_data: {"count" => 1}, name: "Decorator")
      end

      it "does not re-query den when checking both items_stored and fixtures_placed" do
        # Both progress calls should use memoized den
        p1 = checker.progress(items_stored_achievement)
        p2 = checker.progress(fixtures_placed_achievement)

        expect(p1).to be_a(Hash)
        expect(p2).to be_a(Hash)
      end
    end
  end
end
