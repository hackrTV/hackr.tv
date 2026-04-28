require "rails_helper"

RSpec.describe "Dialogue Branching" do
  let(:zone) { create(:grid_zone) }
  let(:room) { create(:grid_room, grid_zone: zone) }
  let(:hackr) { create(:grid_hackr, current_room: room) }

  let(:branching_tree) do
    {
      "greeting" => "Welcome, operative.",
      "topics" => {
        "mission" => {
          "response" => "Our mission is critical.",
          "topics" => {
            "details" => {
              "response" => "Deep operations inside the RIDE.",
              "topics" => {
                "classified" => {
                  "response" => "Eyes only intel."
                }
              }
            },
            "reward" => {
              "response" => "CRED and clearance await."
            }
          }
        },
        "help" => {
          "response" => "Need assistance?"
        }
      }
    }
  end

  let!(:mob) { create(:grid_mob, grid_room: room, name: "Commander", dialogue_tree: branching_tree) }

  def execute(input)
    Grid::CommandParser.new(hackr, input).execute
  end

  describe "talk command with branching" do
    it "shows greeting and root topics initially" do
      result = execute("talk Commander")
      expect(result[:output]).to include("Welcome, operative.")
      expect(result[:output]).to include("mission")
      expect(result[:output]).to include("help")
    end

    it "shows [+] indicator for topics with children" do
      result = execute("talk Commander")
      expect(result[:output]).to include("[+]")
    end

    it "shows current depth topics after navigation" do
      execute("ask Commander about mission")
      result = execute("talk Commander")
      expect(result[:output]).not_to include("Welcome, operative.")
      expect(result[:output]).to include("details")
      expect(result[:output]).to include("reward")
    end

    it "shows breadcrumb when not at root" do
      execute("ask Commander about mission")
      result = execute("talk Commander")
      expect(result[:output]).to include("mission")
    end

    it "resets to root with 'again'" do
      execute("ask Commander about mission")
      result = execute("talk to Commander again")
      expect(result[:output]).to include("Welcome, operative.")
    end

    it "resets to root with 'reset'" do
      execute("ask Commander about mission")
      result = execute("talk to Commander reset")
      expect(result[:output]).to include("Welcome, operative.")
    end

    it "resets to root with 'start'" do
      execute("ask Commander about mission")
      result = execute("talk to Commander start")
      expect(result[:output]).to include("Welcome, operative.")
    end

    it "resets to root with 'over'" do
      execute("ask Commander about mission")
      result = execute("talk to Commander over")
      expect(result[:output]).to include("Welcome, operative.")
    end
  end

  describe "ask command with branching" do
    it "shows response for a root topic" do
      result = execute("ask Commander about mission")
      expect(result[:output]).to include("Our mission is critical.")
    end

    it "shows sub-topics when topic has children" do
      result = execute("ask Commander about mission")
      expect(result[:output]).to include("details")
      expect(result[:output]).to include("reward")
    end

    it "navigates deeper into the tree" do
      execute("ask Commander about mission")
      result = execute("ask Commander about details")
      expect(result[:output]).to include("Deep operations inside the RIDE.")
    end

    it "navigates to a leaf node" do
      execute("ask Commander about mission")
      execute("ask Commander about details")
      result = execute("ask Commander about classified")
      expect(result[:output]).to include("Eyes only intel.")
    end

    it "stays at current depth for leaf topics (siblings reachable)" do
      execute("ask Commander about mission")
      execute("ask Commander about reward")  # leaf — stays at mission level
      result = execute("ask Commander about details")  # sibling should work
      expect(result[:output]).to include("Deep operations inside the RIDE.")
    end

    it "shows error for topic not found at any depth" do
      execute("ask Commander about mission")
      result = execute("ask Commander about nonsense")
      expect(result[:output]).to include("doesn't know about 'nonsense'")
      expect(result[:output]).to include("details")
      expect(result[:output]).to include("reward")
    end
  end

  describe "ancestor topic fallback" do
    it "reaches a root topic from a deeper level" do
      execute("ask Commander about mission")
      execute("ask Commander about details")
      result = execute("ask Commander about help")
      expect(result[:output]).to include("Need assistance?")
    end

    it "reaches a parent topic from a child level" do
      execute("ask Commander about mission")
      execute("ask Commander about details")
      result = execute("ask Commander about reward")  # sibling at mission level
      expect(result[:output]).to include("CRED and clearance await.")
    end

    it "does not change context when responding from ancestor" do
      execute("ask Commander about mission")
      execute("ask Commander about details")
      execute("ask Commander about help")  # root-level — should NOT move context
      hackr.reload
      expect(hackr.dialogue_path_for(mob)).to eq(["mission", "details"])
    end

    it "still advances context for current-depth topics with children" do
      execute("ask Commander about mission")  # has children → advances
      hackr.reload
      expect(hackr.dialogue_path_for(mob)).to eq(["mission"])
    end

    it "shows current-depth topics in error when truly not found" do
      execute("ask Commander about mission")
      execute("ask Commander about details")
      result = execute("ask Commander about nonsense")
      expect(result[:output]).to include("doesn't know about 'nonsense'")
    end

    it "reaches topics in other branches via global search" do
      # Add a topic under "help" to test cross-branch access
      tree = mob.dialogue_tree.deep_dup
      tree["topics"]["help"]["topics"] = {
        "faq" => {"response" => "Frequently asked questions here."}
      }
      mob.update!(dialogue_tree: tree)

      execute("ask Commander about mission")
      execute("ask Commander about details")
      # Now at ["mission", "details"], ask about "faq" which is under ["help"]
      result = execute("ask Commander about faq")
      expect(result[:output]).to include("Frequently asked questions here.")
    end

    it "does not change context on cross-branch match" do
      tree = mob.dialogue_tree.deep_dup
      tree["topics"]["help"]["topics"] = {
        "faq" => {"response" => "FAQ content."}
      }
      mob.update!(dialogue_tree: tree)

      execute("ask Commander about mission")
      execute("ask Commander about details")
      execute("ask Commander about faq")
      hackr.reload
      expect(hackr.dialogue_path_for(mob)).to eq(["mission", "details"])
    end
  end

  describe "back navigation" do
    it "goes up one level with 'back'" do
      execute("ask Commander about mission")
      execute("ask Commander about details")
      result = execute("ask Commander about back")
      # Should re-render the mission level via talk
      expect(result[:output]).to include("details")
      expect(result[:output]).to include("reward")
    end

    it "goes up one level with 'up'" do
      execute("ask Commander about mission")
      result = execute("ask Commander about up")
      # Back to root, rendered via talk
      expect(result[:output]).to include("Welcome, operative.")
    end

    it "stays at root if already there" do
      result = execute("ask Commander about back")
      expect(result[:output]).to include("already at the start")
    end
  end

  describe "dialogue tree normalization" do
    it "normalizes flat string topics to nested format" do
      mob = create(:grid_mob, grid_room: room, name: "Old NPC", dialogue_tree: {
        "greeting" => "Hi",
        "topics" => {
          "test" => "A flat string response"
        }
      })
      expect(mob.reload.dialogue_tree["topics"]["test"]).to eq({"response" => "A flat string response"})
    end

    it "preserves already-nested topics" do
      mob = create(:grid_mob, grid_room: room, name: "New NPC", dialogue_tree: {
        "greeting" => "Hi",
        "topics" => {
          "test" => {"response" => "Already nested", "topics" => {"sub" => {"response" => "Sub"}}}
        }
      })
      expect(mob.reload.dialogue_tree["topics"]["test"]["response"]).to eq("Already nested")
      expect(mob.reload.dialogue_tree["topics"]["test"]["topics"]["sub"]["response"]).to eq("Sub")
    end
  end

  describe "dialogue tree unique key validation" do
    it "rejects duplicate topic keys across branches" do
      tree = {
        "greeting" => "Hi",
        "topics" => {
          "mission" => {
            "response" => "Mission info.",
            "topics" => {
              "help" => {"response" => "Mission help."}
            }
          },
          "help" => {"response" => "General help."}
        }
      }
      mob = build(:grid_mob, grid_room: room, name: "Dupe NPC", dialogue_tree: tree)
      expect(mob).not_to be_valid
      expect(mob.errors[:dialogue_tree].first).to include("duplicate topic key 'help'")
    end

    it "rejects case-insensitive duplicates" do
      tree = {
        "greeting" => "Hi",
        "topics" => {
          "Help" => {"response" => "One"},
          "help" => {"response" => "Two"}
        }
      }
      mob = build(:grid_mob, grid_room: room, name: "Case NPC", dialogue_tree: tree)
      expect(mob).not_to be_valid
      expect(mob.errors[:dialogue_tree].first).to include("duplicate topic key 'help'")
    end

    it "accepts trees with unique keys" do
      tree = {
        "greeting" => "Hi",
        "topics" => {
          "mission" => {
            "response" => "Info.",
            "topics" => {
              "details" => {"response" => "Details."}
            }
          },
          "help" => {"response" => "Help."}
        }
      }
      mob = build(:grid_mob, grid_room: room, name: "Unique NPC", dialogue_tree: tree)
      expect(mob).to be_valid
    end
  end

  describe "dialogue tree depth validation" do
    it "rejects trees exceeding max depth" do
      # Build a tree deeply enough to trigger the JSON nesting guard.
      # Each dialogue level adds ~2 JSON nesting levels, so 50+ levels
      # will hit Ruby's JSON nesting limit (100) before our own depth
      # validation fires — the normalizer rescues this and adds an error.
      tree = {"greeting" => "Hi", "topics" => {}}
      node = tree["topics"]
      60.times do |i|
        node["level#{i}"] = {"response" => "Level #{i}", "topics" => {}}
        node = node["level#{i}"]["topics"]
      end

      mob = build(:grid_mob, grid_room: room, name: "Deep NPC", dialogue_tree: tree)
      expect(mob).not_to be_valid
      expect(mob.errors[:dialogue_tree].first).to include("nested")
    end

    it "accepts trees within depth limit" do
      tree = {"greeting" => "Hi", "topics" => {
        "a" => {"response" => "1", "topics" => {
          "b" => {"response" => "2", "topics" => {
            "c" => {"response" => "3"}
          }}
        }}
      }}
      mob = build(:grid_mob, grid_room: room, name: "Shallow NPC", dialogue_tree: tree)
      expect(mob).to be_valid
    end
  end

  describe "dialogue context helpers on GridHackr" do
    it "tracks dialogue path per mob" do
      hackr.set_dialogue_path(mob, ["mission", "details"])
      expect(hackr.dialogue_path_for(mob)).to eq(["mission", "details"])
    end

    it "clears dialogue path for a mob" do
      hackr.set_dialogue_path(mob, ["mission"])
      hackr.clear_dialogue_path(mob)
      expect(hackr.dialogue_path_for(mob)).to eq([])
    end

    it "tracks independent paths for different mobs" do
      other_mob = create(:grid_mob, grid_room: room, name: "Other", dialogue_tree: branching_tree)
      hackr.set_dialogue_path(mob, ["mission"])
      hackr.set_dialogue_path(other_mob, ["help"])
      expect(hackr.dialogue_path_for(mob)).to eq(["mission"])
      expect(hackr.dialogue_path_for(other_mob)).to eq(["help"])
    end
  end

  describe "mission dialogue path gating" do
    let(:faction) { create(:grid_faction) }
    let!(:quest_mob) do
      create(:grid_mob,
        grid_room: room,
        name: "Quest Giver",
        mob_type: "quest_giver",
        grid_faction: faction,
        dialogue_tree: branching_tree)
    end

    let!(:surface_mission) do
      create(:grid_mission,
        name: "Surface Job",
        slug: "surface-job",
        giver_mob: quest_mob,
        published: true,
        dialogue_path: nil)
    end

    let!(:buried_mission) do
      create(:grid_mission,
        name: "Buried Job",
        slug: "buried-job",
        giver_mob: quest_mob,
        published: true,
        dialogue_path: ["mission", "details"])
    end

    it "shows ungated missions at any depth" do
      result = execute("ask Quest Giver about missions")
      expect(result[:output]).to include("surface-job")
    end

    it "hides dialogue-gated missions when not at required depth" do
      result = execute("ask Quest Giver about missions")
      expect(result[:output]).not_to include("buried-job")
    end

    it "shows dialogue-gated missions when at required depth" do
      execute("ask Quest Giver about mission")
      execute("ask Quest Giver about details")
      hackr.reload
      result = execute("ask Quest Giver about missions")
      expect(result[:output]).to include("buried-job")
    end

    it "blocks direct slug access for gated missions" do
      result = execute("ask Quest Giver about buried-job")
      # Should fall through to dialogue topic lookup, not show mission brief
      expect(result[:output]).not_to include("Buried Job")
    end

    it "allows direct slug access when at required depth" do
      execute("ask Quest Giver about mission")
      execute("ask Quest Giver about details")
      hackr.reload
      result = execute("ask Quest Giver about buried-job")
      expect(result[:output]).to include("Buried Job")
    end

    it "blocks accept for gated missions" do
      result = execute("accept buried-job")
      expect(result[:output]).to include("haven't learned")
    end

    it "allows accept when at required depth" do
      execute("ask Quest Giver about mission")
      execute("ask Quest Giver about details")
      hackr.reload
      result = execute("accept buried-job")
      expect(result[:output]).to include("MISSION ACCEPTED")
    end
  end

  describe "back navigation does not grant stats/rep" do
    let(:faction) { create(:grid_faction) }
    let!(:npc) do
      create(:grid_mob,
        grid_room: room,
        name: "Talker",
        grid_faction: faction,
        dialogue_tree: branching_tree)
    end

    it "does not increment npcs_talked on back" do
      execute("talk Talker")
      execute("ask Talker about mission")
      initial = hackr.reload.stat("npcs_talked")
      execute("ask Talker about back")
      expect(hackr.reload.stat("npcs_talked")).to eq(initial)
    end
  end
end
