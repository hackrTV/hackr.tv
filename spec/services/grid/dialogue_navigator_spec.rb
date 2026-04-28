require "rails_helper"

RSpec.describe Grid::DialogueNavigator do
  let(:zone) { create(:grid_zone) }
  let(:room) { create(:grid_room, grid_zone: zone) }
  let(:hackr) { create(:grid_hackr, current_room: room) }

  let(:dialogue_tree) do
    {
      "greeting" => "Welcome, hackr.",
      "topics" => {
        "mission" => {
          "response" => "Our mission is critical.",
          "topics" => {
            "details" => {
              "response" => "Deep inside the RIDE...",
              "topics" => {
                "classified" => {
                  "response" => "Eyes only, hackr."
                }
              }
            },
            "reward" => {
              "response" => "CRED and clearance."
            }
          }
        },
        "help" => {
          "response" => "Need a hand?"
        }
      }
    }
  end

  let(:mob) { create(:grid_mob, grid_room: room, name: "Coordinator", dialogue_tree: dialogue_tree) }
  let(:nav) { described_class.new(hackr: hackr, mob: mob) }

  describe "#current_path" do
    it "returns empty array at root" do
      expect(nav.current_path).to eq([])
    end

    it "returns stored path when context exists" do
      hackr.set_dialogue_path(mob, ["mission"])
      expect(nav.current_path).to eq(["mission"])
    end
  end

  describe "#at_root?" do
    it "is true initially" do
      expect(nav).to be_at_root
    end

    it "is false after navigation" do
      hackr.set_dialogue_path(mob, ["mission"])
      expect(nav).not_to be_at_root
    end
  end

  describe "#greeting" do
    it "returns the greeting text" do
      expect(nav.greeting).to eq("Welcome, hackr.")
    end
  end

  describe "#node_at" do
    it "returns root for empty path" do
      node = nav.node_at([])
      expect(node["greeting"]).to eq("Welcome, hackr.")
    end

    it "returns a topic node" do
      node = nav.node_at(["mission"])
      expect(node["response"]).to eq("Our mission is critical.")
    end

    it "returns a deeply nested node" do
      node = nav.node_at(["mission", "details", "classified"])
      expect(node["response"]).to eq("Eyes only, hackr.")
    end

    it "returns nil for invalid path" do
      expect(nav.node_at(["nonexistent"])).to be_nil
    end
  end

  describe "#current_topics" do
    it "returns root topics when at root" do
      topics = nav.current_topics
      expect(topics.keys).to contain_exactly("mission", "help")
    end

    it "returns sub-topics when navigated" do
      hackr.set_dialogue_path(mob, ["mission"])
      topics = nav.current_topics
      expect(topics.keys).to contain_exactly("details", "reward")
    end
  end

  describe "#navigate" do
    it "returns response and sub-topics for a valid topic" do
      result = nav.navigate("mission")
      expect(result[:response]).to eq("Our mission is critical.")
      expect(result[:topics].keys).to contain_exactly("details", "reward")
    end

    it "advances context when target has sub-topics" do
      nav.navigate("mission")
      expect(hackr.dialogue_path_for(mob)).to eq(["mission"])
    end

    it "does not advance context for leaf topics" do
      nav.navigate("help")
      expect(hackr.dialogue_path_for(mob)).to eq([])
    end

    it "navigates deeper within context" do
      nav.navigate("mission")
      result = nav.navigate("details")
      expect(result[:response]).to eq("Deep inside the RIDE...")
      expect(hackr.dialogue_path_for(mob)).to eq(["mission", "details"])
    end

    it "finds ancestor topics without changing context" do
      nav.navigate("mission") # context → ["mission"]
      nav.navigate("details") # context → ["mission", "details"]
      result = nav.navigate("help") # root-level, ancestor hit
      expect(result[:response]).to eq("Need a hand?")
      expect(hackr.dialogue_path_for(mob)).to eq(["mission", "details"])
    end

    it "finds cross-branch topics via global search" do
      # Add sub-topic under "help"
      tree = mob.dialogue_tree.deep_dup
      tree["topics"]["help"]["topics"] = {
        "faq" => {"response" => "FAQ answer."}
      }
      mob.update!(dialogue_tree: tree)
      fresh_nav = described_class.new(hackr: hackr, mob: mob.reload)

      fresh_nav.navigate("mission")
      fresh_nav.navigate("details")
      result = fresh_nav.navigate("faq")
      expect(result[:response]).to eq("FAQ answer.")
      expect(hackr.dialogue_path_for(mob)).to eq(["mission", "details"])
    end

    it "returns nil for unknown topic" do
      expect(nav.navigate("nonsense")).to be_nil
    end

    it "handles case-insensitive lookup" do
      result = nav.navigate("MISSION")
      expect(result[:response]).to eq("Our mission is critical.")
    end
  end

  describe "#go_back" do
    it "returns empty path when already at root" do
      expect(nav.go_back).to eq([])
    end

    it "goes up one level" do
      hackr.set_dialogue_path(mob, ["mission", "details"])
      new_path = nav.go_back
      expect(new_path).to eq(["mission"])
      expect(hackr.dialogue_path_for(mob)).to eq(["mission"])
    end

    it "goes to root from depth 1" do
      hackr.set_dialogue_path(mob, ["mission"])
      new_path = nav.go_back
      expect(new_path).to eq([])
      expect(hackr.dialogue_path_for(mob)).to eq([])
    end
  end

  describe "#reset!" do
    it "clears dialogue context" do
      hackr.set_dialogue_path(mob, ["mission", "details"])
      nav.reset!
      expect(hackr.dialogue_path_for(mob)).to eq([])
    end
  end

  describe ".reset_alias?" do
    it "recognizes reset aliases" do
      %w[again reset start over].each do |word|
        expect(described_class.reset_alias?(word)).to be true
      end
    end

    it "rejects non-aliases" do
      expect(described_class.reset_alias?("mission")).to be false
    end
  end

  describe ".back_alias?" do
    it "recognizes back aliases" do
      %w[back up ..].each do |word|
        expect(described_class.back_alias?(word)).to be true
      end
    end
  end

  describe ".has_children?" do
    it "returns true for nodes with sub-topics" do
      node = {"response" => "test", "topics" => {"sub" => {"response" => "x"}}}
      expect(described_class.has_children?(node)).to be true
    end

    it "returns false for leaf nodes" do
      node = {"response" => "test"}
      expect(described_class.has_children?(node)).to be false
    end

    it "returns false for empty topics" do
      node = {"response" => "test", "topics" => {}}
      expect(described_class.has_children?(node)).to be false
    end
  end
end
