require "rails_helper"

RSpec.describe GridSchematicIngredient do
  let(:output_def) { create(:grid_item_definition, slug: "output-item") }
  let(:input_def) { create(:grid_item_definition, slug: "input-item") }
  let(:schematic) do
    GridSchematic.create!(slug: "test-sch", name: "Test", output_definition: output_def)
  end

  describe "validations" do
    it "is valid with valid attributes" do
      ingredient = described_class.new(
        grid_schematic: schematic, input_definition: input_def, quantity: 2
      )
      expect(ingredient).to be_valid
    end

    it "requires quantity > 0" do
      ingredient = described_class.new(
        grid_schematic: schematic, input_definition: input_def, quantity: 0
      )
      expect(ingredient).not_to be_valid
      expect(ingredient.errors[:quantity]).to be_present
    end

    it "enforces unique input per schematic" do
      described_class.create!(grid_schematic: schematic, input_definition: input_def)
      duplicate = described_class.new(grid_schematic: schematic, input_definition: input_def)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:input_definition_id]).to include(
        "already configured as an ingredient for this schematic"
      )
    end

    it "prevents input same as output" do
      ingredient = described_class.new(
        grid_schematic: schematic, input_definition: output_def, quantity: 1
      )
      expect(ingredient).not_to be_valid
      expect(ingredient.errors[:input_definition_id]).to include("cannot be the same as the output")
    end
  end

  describe ".ordered" do
    it "orders by position then id" do
      i2 = described_class.create!(grid_schematic: schematic, input_definition: input_def, position: 1)
      input2 = create(:grid_item_definition, slug: "input-2")
      i1 = described_class.create!(grid_schematic: schematic, input_definition: input2, position: 0)

      expect(described_class.ordered.to_a).to eq([i1, i2])
    end
  end

  describe "dependent destroy" do
    it "is destroyed when schematic is destroyed" do
      described_class.create!(grid_schematic: schematic, input_definition: input_def)
      expect { schematic.destroy! }.to change(described_class, :count).by(-1)
    end
  end
end
