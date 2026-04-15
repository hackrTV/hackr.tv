require "rails_helper"

RSpec.describe Grid::AchievementChecker do
  let(:hackr) { create(:grid_hackr) }
  let(:checker) { described_class.new(hackr) }

  describe "#check — existing MUD triggers still work" do
    let!(:achievement) do
      create(:grid_achievement,
        slug: "rooms-5",
        trigger_type: "rooms_visited",
        trigger_data: {"count" => 5},
        xp_reward: 25)
    end

    it "awards when stat meets threshold" do
      hackr.set_stat!("rooms_visited", 5)
      expect { checker.check("rooms_visited") }
        .to change { hackr.grid_hackr_achievements.count }.by(1)
    end

    it "does not award when below threshold" do
      hackr.set_stat!("rooms_visited", 3)
      expect { checker.check("rooms_visited") }
        .not_to change { hackr.grid_hackr_achievements.count }
    end

    it "is idempotent across multiple calls" do
      hackr.set_stat!("rooms_visited", 5)
      checker.check("rooms_visited")
      expect { checker.check("rooms_visited") }
        .not_to change { hackr.grid_hackr_achievements.count }
    end

    it "returns a notification array when awarded" do
      hackr.set_stat!("rooms_visited", 5)
      notifications = checker.check("rooms_visited")
      expect(notifications.size).to eq(1)
      expect(notifications.first).to include("ACHIEVEMENT UNLOCKED")
    end

    it "returns [] when no matches" do
      hackr.set_stat!("rooms_visited", 0)
      expect(checker.check("rooms_visited")).to eq([])
    end
  end

  describe "#check — track_plays_count" do
    let!(:artist) { create(:artist) }
    let!(:release) { create(:release, artist: artist) }
    let!(:tracks) { create_list(:track, 3, artist: artist, release: release) }

    before do
      create(:grid_achievement,
        slug: "music-3-tracks",
        category: "music",
        trigger_type: "track_plays_count",
        trigger_data: {"count" => 3},
        xp_reward: 25)
    end

    it "awards when 3 unique tracks have been credited" do
      tracks.each { |t| GridHackrTrackPlay.record!(hackr, t) }
      expect { checker.check("track_plays_count") }
        .to change { hackr.grid_hackr_achievements.count }.by(1)
    end

    it "does not award with only 2 plays" do
      tracks.take(2).each { |t| GridHackrTrackPlay.record!(hackr, t) }
      expect { checker.check("track_plays_count") }
        .not_to change { hackr.grid_hackr_achievements.count }
    end

    it "counts replays of the same track only once" do
      3.times { GridHackrTrackPlay.record!(hackr, tracks.first) }
      expect { checker.check("track_plays_count") }
        .not_to change { hackr.grid_hackr_achievements.count }
    end
  end

  describe "#check — hackr_logs_read_all" do
    before do
      create(:grid_achievement,
        slug: "all-logs",
        category: "meta",
        trigger_type: "hackr_logs_read_all",
        trigger_data: {},
        xp_reward: 500)
    end

    it "does not fire when no logs are published" do
      expect { checker.check("hackr_logs_read_all") }
        .not_to change { hackr.grid_hackr_achievements.count }
    end

    it "fires when all published logs have been read" do
      logs = create_list(:hackr_log, 3, :published)
      logs.each { |log| HackrLogRead.record!(hackr, log) }
      expect { checker.check("hackr_logs_read_all") }
        .to change { hackr.grid_hackr_achievements.count }.by(1)
    end

    it "does not fire when one log is unread" do
      logs = create_list(:hackr_log, 3, :published)
      logs.take(2).each { |log| HackrLogRead.record!(hackr, log) }
      expect { checker.check("hackr_logs_read_all") }
        .not_to change { hackr.grid_hackr_achievements.count }
    end
  end

  describe "#check — radio_stations_tuned_all" do
    before do
      create(:grid_achievement,
        slug: "all-radio",
        category: "music",
        trigger_type: "radio_stations_tuned_all",
        trigger_data: {},
        xp_reward: 500)
    end

    it "awards when every visible station has been tuned" do
      stations = create_list(:radio_station, 3)
      stations.each { |s| HackrRadioTune.record!(hackr, s) }
      expect { checker.check("radio_stations_tuned_all") }
        .to change { hackr.grid_hackr_achievements.count }.by(1)
    end

    it "ignores hidden stations from the target count" do
      create_list(:radio_station, 2) # visible
      hidden = create(:radio_station, hidden: true)
      # Tune only the 2 visible stations — the hidden one doesn't count toward "all"
      RadioStation.visible.each { |s| HackrRadioTune.record!(hackr, s) }
      HackrRadioTune.record!(hackr, hidden)
      expect { checker.check("radio_stations_tuned_all") }
        .to change { hackr.grid_hackr_achievements.count }.by(1)
    end
  end

  describe "#check — clearance_level" do
    before do
      create(:grid_achievement,
        slug: "cl-5",
        category: "progression",
        trigger_type: "clearance_level",
        trigger_data: {"level" => 5},
        xp_reward: 0,
        cred_reward: 0)
    end

    it "fires once the hackr reaches the target clearance" do
      hackr.set_stat!("clearance", 5)
      expect { checker.check("clearance_level") }
        .to change { hackr.grid_hackr_achievements.count }.by(1)
    end

    it "does not fire at CL4" do
      hackr.set_stat!("clearance", 4)
      expect { checker.check("clearance_level") }
        .not_to change { hackr.grid_hackr_achievements.count }
    end
  end

  describe "#check — earned_ids memoization" do
    # Regression: the login sweep job calls check() 18 times on one
    # checker instance. Without earned_ids memoization, each call
    # re-pluck's the join table — 18 identical queries per sweep.

    it "reads grid_hackr_achievements.id only once across repeated check() calls" do
      create(:grid_achievement, slug: "a", trigger_type: "rooms_visited", trigger_data: {"count" => 1})
      create(:grid_achievement, slug: "b", trigger_type: "track_plays_count", trigger_data: {"count" => 1})
      create(:grid_achievement, slug: "c", trigger_type: "hackr_logs_read", trigger_data: {"count" => 1})

      query_count = 0
      counter = ->(_name, _start, _finish, _id, payload) do
        sql = payload[:sql].to_s
        query_count += 1 if sql.include?("grid_hackr_achievements") && sql.include?("grid_achievement_id")
      end

      ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
        checker.check("rooms_visited")
        checker.check("track_plays_count")
        checker.check("hackr_logs_read")
      end

      expect(query_count).to eq(1)
    end

    it "marks awards from within the same instance as earned so later check() calls skip them" do
      create(:grid_achievement,
        slug: "rooms-1",
        trigger_type: "rooms_visited",
        trigger_data: {"count" => 1},
        xp_reward: 10)
      hackr.set_stat!("rooms_visited", 1)

      # First check — awards it and tracks earned_ids internally.
      expect { checker.check("rooms_visited") }
        .to change { hackr.grid_hackr_achievements.count }.by(1)

      # Second check on same instance — earned_ids now contains this
      # achievement, so it's skipped. award! is never re-invoked even
      # at the Awarder layer.
      expect(Grid::AchievementAwarder).not_to receive(:new)
      checker.check("rooms_visited")
    end
  end

  describe "#progress query count (memoization)" do
    # Regression: the AchievementsPage endpoint calls `progress` for
    # every achievement. Many share the same underlying count (e.g.
    # all `hackr_logs_read` tiers hit `hackr_log_reads.count`).
    # Memoization must collapse repeated reads to one query each.

    it "reads hackr_log_reads.count only once across many achievements" do
      a1 = create(:grid_achievement, slug: "lr-1", trigger_type: "hackr_logs_read", trigger_data: {"count" => 1})
      a2 = create(:grid_achievement, slug: "lr-10", trigger_type: "hackr_logs_read", trigger_data: {"count" => 10})
      a3 = create(:grid_achievement, slug: "lr-25", trigger_type: "hackr_logs_read", trigger_data: {"count" => 25})

      # Query counter for the specific count query
      query_count = 0
      counter = ->(_name, _start, _finish, _id, payload) do
        sql = payload[:sql].to_s
        query_count += 1 if sql.include?("hackr_log_reads") && sql.include?("COUNT(")
      end

      ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
        checker.progress(a1)
        checker.progress(a2)
        checker.progress(a3)
      end

      expect(query_count).to eq(1)
    end

    it "reads published HackrLog total only once" do
      a1 = create(:grid_achievement, slug: "lra-1", trigger_type: "hackr_logs_read_all", trigger_data: {})
      a2 = create(:grid_achievement, slug: "lra-2", trigger_type: "hackr_logs_read_all", trigger_data: {})

      query_count = 0
      counter = ->(_name, _start, _finish, _id, payload) do
        sql = payload[:sql].to_s
        # Matches the `HackrLog.published.count` for the target total
        query_count += 1 if sql.include?("hackr_logs") && sql.include?("COUNT(") && !sql.include?("hackr_log_reads")
      end

      ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
        checker.progress(a1)
        checker.progress(a2)
      end

      expect(query_count).to eq(1)
    end
  end

  describe "#progress" do
    let!(:achievement) do
      create(:grid_achievement,
        trigger_type: "rooms_visited",
        trigger_data: {"count" => 10})
    end

    it "returns fraction/current/target for cumulative triggers" do
      hackr.set_stat!("rooms_visited", 3)
      progress = checker.progress(achievement)
      expect(progress).to include(current: 3, target: 10, fraction: 0.3, completed: false)
    end

    it "clamps the fraction at 1.0 when exceeded" do
      hackr.set_stat!("rooms_visited", 25)
      progress = checker.progress(achievement)
      expect(progress[:fraction]).to eq(1.0)
      expect(progress[:completed]).to be true
    end

    it "returns nil for event-only triggers like take_item" do
      event_achievement = create(:grid_achievement,
        slug: "take-specific",
        trigger_type: "take_item",
        trigger_data: {"item_name" => "data chip"})
      expect(checker.progress(event_achievement)).to be_nil
    end
  end
end
