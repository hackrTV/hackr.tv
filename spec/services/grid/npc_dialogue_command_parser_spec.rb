require "rails_helper"

RSpec.describe Grid::NpcDialogueCommandParser do
  let(:zone) { create(:grid_zone) }
  let(:room) { create(:grid_room, grid_zone: zone) }
  let(:hackr) { create(:grid_hackr, current_room: room) }
  let(:mob) do
    create(:grid_mob,
      grid_room: room,
      name: "Test NPC",
      dialogue_tree: {
        "greeting" => "Hello, hackr!",
        "topics" => {
          "mission" => "We need your help.",
          "lore" => "Let me tell you a story..."
        }
      })
  end
  let(:parser) { described_class.new(hackr, input) }

  before { mob }

  describe "allowed read commands" do
    context "talk command" do
      let(:input) { "talk Test NPC" }

      it "returns the greeting" do
        result = parser.execute
        expect(result[:output]).to include("Hello, hackr!")
      end

      it "lists available topics" do
        result = parser.execute
        expect(result[:output]).to include("mission")
        expect(result[:output]).to include("lore")
      end
    end

    context "ask command" do
      let(:input) { "ask Test NPC about mission" }

      it "returns the topic response" do
        result = parser.execute
        expect(result[:output]).to include("We need your help.")
      end
    end

    context "examine command" do
      let(:input) { "examine Test NPC" }

      it "returns mob description" do
        result = parser.execute
        expect(result[:output]).to include(mob.description)
      end
    end

    context "look command" do
      let(:input) { "look" }

      it "returns room description with mob listed" do
        result = parser.execute
        expect(result[:output]).to include(room.name.upcase)
        expect(result[:output]).to include("Test NPC")
      end
    end

    context "stat command" do
      let(:input) { "stat" }

      it "returns hackr stats" do
        result = parser.execute
        expect(result[:output]).to include(hackr.hackr_alias)
      end
    end

    context "help command" do
      let(:input) { "help" }

      it "returns help text" do
        result = parser.execute
        expect(result[:output]).to be_present
      end
    end
  end

  describe "side effect suppression" do
    context "talk command" do
      let(:input) { "talk Test NPC" }

      it "does not increment npcs_talked stat" do
        initial = hackr.stat("npcs_talked") || 0
        parser.execute
        hackr.reload
        expect(hackr.stat("npcs_talked") || 0).to eq(initial)
      end

      it "returns greeting output despite suppressed side effects" do
        result = parser.execute
        expect(result[:output]).to include("Hello, hackr!")
      end
    end

    context "talk to NPC with faction" do
      let(:faction) { create(:grid_faction) }
      let(:mob_with_faction) do
        create(:grid_mob,
          grid_room: room,
          name: "Faction NPC",
          grid_faction: faction,
          dialogue_tree: {"greeting" => "Welcome, ally."})
      end

      before { mob_with_faction }

      let(:input) { "talk Faction NPC" }

      it "does not grant faction reputation" do
        parser.execute
        rep_record = GridHackrReputation.find_by(
          grid_hackr_id: hackr.id,
          subject_type: "GridFaction",
          subject_id: faction.id
        )
        expect(rep_record).to be_nil
      end
    end
  end

  describe "blocked commands" do
    context "disallowed command" do
      let(:input) { "go north" }

      it "returns not available message" do
        result = parser.execute
        expect(result[:output]).to include("[TESTER] Command not available")
      end
    end

    %w[drop take salvage fabricate equip unequip breach rig den].each do |cmd|
      context "#{cmd} command" do
        let(:input) { cmd }

        it "is blocked" do
          result = parser.execute
          expect(result[:output]).to include("[TESTER] Command not available")
        end
      end
    end
  end

  describe "write commands with rollback" do
    context "buy command with no vendor" do
      let(:input) { "buy something" }

      it "returns error from inherited command with rollback notice" do
        result = parser.execute
        expect(result[:output]).to include("no vendor here")
        expect(result[:output]).to include("[TESTER] Write reverted")
      end
    end

    context "accept command with nonexistent mission" do
      let(:input) { "accept some-mission" }

      it "returns error from inherited command with rollback notice" do
        result = parser.execute
        expect(result[:output]).to be_present
        expect(result[:output]).to include("[TESTER] Write reverted")
      end
    end
  end

  describe "bypasses breach/captured routing" do
    let(:input) { "look" }

    it "executes normally even with breach active" do
      # Create an active breach on the hackr (factory defaults to state: "active")
      template = create(:grid_breach_template)
      create(:grid_hackr_breach, grid_hackr: hackr, grid_breach_template: template)
      hackr.reload

      # Regular CommandParser would route to BreachCommandParser
      # NpcDialogueCommandParser bypasses that
      result = parser.execute
      expect(result[:output]).to include(room.name.upcase)
    end
  end
end
