require "rails_helper"

RSpec.describe Grid::CommandParser do
  let(:zone) { create(:grid_zone) }
  let(:room) { create(:grid_room, grid_zone: zone) }
  let(:hackr) { create(:grid_hackr, current_room: room) }
  let(:parser) { described_class.new(hackr, input) }

  describe "#execute" do
    describe "talk command" do
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

      context "with valid NPC name" do
        let(:input) { "talk Test NPC" }

        before { mob } # ensure mob exists

        it "returns the greeting" do
          result = parser.execute
          expect(result[:output]).to include("Hello, hackr!")
        end

        it "lists available topics" do
          result = parser.execute
          expect(result[:output]).to include("You can ask about:")
          expect(result[:output]).to include("mission")
          expect(result[:output]).to include("lore")
        end
      end

      context "with 'talk to' syntax" do
        let(:input) { "talk to Test NPC" }

        before { mob }

        it "works with 'to' prefix" do
          result = parser.execute
          expect(result[:output]).to include("Hello, hackr!")
        end
      end

      context "with case-insensitive name" do
        let(:input) { "talk test npc" }

        before { mob }

        it "finds the NPC regardless of case" do
          result = parser.execute
          expect(result[:output]).to include("Hello, hackr!")
        end
      end

      context "with NPC that has no dialogue" do
        let(:mob) { create(:grid_mob, grid_room: room, name: "Silent NPC", dialogue_tree: nil) }
        let(:input) { "talk Silent NPC" }

        before { mob }

        it "returns a message that NPC doesn't talk" do
          result = parser.execute
          expect(result[:output]).to include("doesn't seem interested in talking")
        end
      end

      context "with NPC that has empty dialogue tree" do
        let(:mob) { create(:grid_mob, grid_room: room, name: "Quiet NPC", dialogue_tree: {}) }
        let(:input) { "talk Quiet NPC" }

        before { mob }

        it "returns a message that NPC doesn't talk" do
          result = parser.execute
          expect(result[:output]).to include("doesn't seem interested in talking")
        end
      end

      context "with non-existent NPC" do
        let(:input) { "talk Nobody" }

        it "returns an error message" do
          result = parser.execute
          expect(result[:output]).to include("You don't see 'Nobody' here")
        end
      end

      context "without NPC name" do
        let(:input) { "talk" }

        it "returns usage message" do
          result = parser.execute
          expect(result[:output]).to include("Talk to whom?")
        end
      end

      context "with NPC in different room" do
        let(:other_room) { create(:grid_room, grid_zone: zone) }
        let(:mob) { create(:grid_mob, grid_room: other_room, name: "Distant NPC", dialogue_tree: {"greeting" => "Hi"}) }
        let(:input) { "talk Distant NPC" }

        before { mob }

        it "doesn't find the NPC" do
          result = parser.execute
          expect(result[:output]).to include("You don't see 'Distant NPC' here")
        end
      end
    end

    describe "ask command" do
      let(:mob) do
        create(:grid_mob,
          grid_room: room,
          name: "Knowledgeable NPC",
          dialogue_tree: {
            "greeting" => "Greetings.",
            "topics" => {
              "mission" => "The mission is critical.",
              "lore" => "Ancient knowledge awaits.",
              "secret" => "I cannot reveal that."
            }
          })
      end

      before { mob }

      context "with valid NPC and topic using 'about'" do
        let(:input) { "ask Knowledgeable NPC about mission" }

        it "returns the topic response" do
          result = parser.execute
          expect(result[:output]).to include("The mission is critical")
        end

        it "includes the NPC name in response" do
          result = parser.execute
          expect(result[:output]).to include("Knowledgeable NPC")
        end
      end

      context "with case-insensitive topic" do
        let(:input) { "ask Knowledgeable NPC about MISSION" }

        it "finds the topic regardless of case" do
          result = parser.execute
          expect(result[:output]).to include("The mission is critical")
        end
      end

      context "with multi-word topic" do
        let(:mob) do
          create(:grid_mob,
            grid_room: room,
            name: "Guide",
            dialogue_tree: {
              "greeting" => "Hello.",
              "topics" => {
                "fracture network" => "We fight for freedom."
              }
            })
        end
        let(:input) { "ask Guide about fracture network" }

        it "handles multi-word topics" do
          result = parser.execute
          expect(result[:output]).to include("We fight for freedom")
        end
      end

      context "with invalid topic" do
        let(:input) { "ask Knowledgeable NPC about nonsense" }

        it "returns error message" do
          result = parser.execute
          expect(result[:output]).to include("doesn't know about 'nonsense'")
        end

        it "suggests available topics" do
          result = parser.execute
          expect(result[:output]).to include("Try asking about:")
          expect(result[:output]).to include("mission")
          expect(result[:output]).to include("lore")
          expect(result[:output]).to include("secret")
        end
      end

      context "with non-existent NPC" do
        let(:input) { "ask Nobody about anything" }

        it "returns error message" do
          result = parser.execute
          expect(result[:output]).to include("You don't see 'Nobody' here")
        end
      end

      context "with NPC that has no dialogue" do
        let(:silent_mob) { create(:grid_mob, grid_room: room, name: "Silent", dialogue_tree: nil) }
        let(:input) { "ask Silent about test" }

        before { silent_mob }

        it "returns message that NPC doesn't talk" do
          result = parser.execute
          expect(result[:output]).to include("doesn't seem interested in talking")
        end
      end

      context "without enough arguments" do
        let(:input) { "ask someone" }

        it "returns usage message" do
          result = parser.execute
          expect(result[:output]).to include("Usage: ask")
          expect(result[:output]).to include("about")
        end
      end

      context "without 'about' keyword" do
        let(:input) { "ask" }

        it "returns usage message" do
          result = parser.execute
          expect(result[:output]).to include("Usage: ask")
          expect(result[:output]).to include("about")
        end
      end

      context "with NPC name but no topic" do
        let(:input) { "ask Knowledgeable NPC about" }

        it "returns error message" do
          result = parser.execute
          expect(result[:output]).to include("Ask whom about what?")
        end
      end
    end

    describe "integration with other commands" do
      let(:mob) do
        create(:grid_mob,
          grid_room: room,
          name: "Helper",
          dialogue_tree: {
            "greeting" => "How can I assist?",
            "topics" => {"help" => "I'm here to help!"}
          })
      end

      before { mob }

      it "talk command returns hash with output and event" do
        parser = described_class.new(hackr, "talk Helper")
        result = parser.execute
        expect(result).to have_key(:output)
        expect(result).to have_key(:event)
      end

      it "ask command returns hash with output and event" do
        parser = described_class.new(hackr, "ask Helper about help")
        result = parser.execute
        expect(result).to have_key(:output)
        expect(result).to have_key(:event)
      end

      it "examine command still works with NPCs" do
        parser = described_class.new(hackr, "examine Helper")
        result = parser.execute
        expect(result[:output]).to include(mob.description)
      end
    end

    describe "say command" do
      context "with clean message" do
        let(:input) { "say Hello fellow hackrs!" }

        it "creates a grid message" do
          expect { parser.execute }.to change(GridMessage, :count).by(1)
        end

        it "returns hash with nil output and event for broadcast" do
          result = parser.execute
          expect(result).to have_key(:output)
          expect(result).to have_key(:event)
          # Output is nil because the broadcast handles display
          expect(result[:output]).to be_nil
          expect(result[:event][:type]).to eq("say")
          expect(result[:event][:message]).to eq("Hello fellow hackrs!")
        end
      end

      context "with profanity in message" do
        let(:input) { "say This is some bullshit" }

        it "does not create a grid message" do
          expect { parser.execute }.not_to change(GridMessage, :count)
        end

        it "returns GovCorp rejection message" do
          result = parser.execute
          expect(result[:output]).to include("GOVCORP CENSOR:")
        end
      end

      context "with empty message" do
        let(:input) { "say" }

        it "returns a prompt message" do
          result = parser.execute
          expect(result[:output]).to include("Say what?")
        end
      end
    end

    describe "analyze command" do
      let(:gpu_def) do
        create(:grid_item_definition, :component, slug: "basic-gpu", name: "Basic GPU", value: 5)
      end

      let(:wafer_def) do
        create(:grid_item_definition, slug: "raw-silicon-wafer",
          name: "Raw Silicon Wafer", item_type: "material", rarity: "scrap", value: 2)
      end

      context "with yields defined" do
        let!(:item) { GridItem.create!(gpu_def.item_attributes.merge(grid_hackr: hackr)) }
        let!(:yield_row) do
          GridSalvageYield.create!(source_definition: gpu_def, output_definition: wafer_def, quantity: 3, position: 0)
        end
        let(:input) { "analyze Basic GPU" }

        it "shows XP and yield preview" do
          result = parser.execute
          expect(result[:output]).to include("ANALYSIS")
          expect(result[:output]).to include("Basic GPU")
          expect(result[:output]).to include("+5 XP")
          expect(result[:output]).to include("Raw Silicon Wafer")
          expect(result[:output]).to include("×3")
        end
      end

      context "with no yields" do
        let!(:tool_def) { create(:grid_item_definition, slug: "signal-analyzer", name: "Signal Analyzer", value: 200) }
        let!(:item) { GridItem.create!(tool_def.item_attributes.merge(grid_hackr: hackr)) }
        let(:input) { "analyze Signal Analyzer" }

        it "shows XP only message" do
          result = parser.execute
          expect(result[:output]).to include("+200 XP")
          expect(result[:output]).to include("No decomposition yields")
        end
      end

      context "with unicorn item" do
        let(:unicorn_def) { create(:grid_item_definition, :unicorn, slug: "unicorn-gem", name: "Unicorn Gem", value: 999) }
        let!(:item) { GridItem.create!(unicorn_def.item_attributes.merge(grid_hackr: hackr)) }
        let(:input) { "analyze Unicorn Gem" }

        it "shows irreducible message" do
          result = parser.execute
          expect(result[:output]).to include("irreducible")
        end
      end

      context "with no item name" do
        let(:input) { "analyze" }

        it "prompts for target" do
          result = parser.execute
          expect(result[:output]).to include("Analyze what?")
        end
      end

      context "with 'an' alias" do
        let!(:tool_def) { create(:grid_item_definition, slug: "some-tool", name: "Some Tool", value: 10) }
        let!(:item) { GridItem.create!(tool_def.item_attributes.merge(grid_hackr: hackr)) }
        let(:input) { "an Some Tool" }

        it "works as alias" do
          result = parser.execute
          expect(result[:output]).to include("ANALYSIS")
        end
      end
    end
  end
end
