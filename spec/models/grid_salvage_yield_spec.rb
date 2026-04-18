# == Schema Information
#
# Table name: grid_salvage_yields
# Database name: primary
#
#  id                   :integer          not null, primary key
#  position             :integer          default(0), not null
#  quantity             :integer          default(1), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  output_definition_id :integer          not null
#  source_definition_id :integer          not null
#
# Indexes
#
#  index_grid_salvage_yields_on_output_definition_id  (output_definition_id)
#  index_grid_salvage_yields_on_source_definition_id  (source_definition_id)
#  index_grid_salvage_yields_unique                   (source_definition_id,output_definition_id) UNIQUE
#
# Foreign Keys
#
#  output_definition_id  (output_definition_id => grid_item_definitions.id)
#  source_definition_id  (source_definition_id => grid_item_definitions.id)
#
require "rails_helper"

RSpec.describe GridSalvageYield do
  let(:source) { create(:grid_item_definition, slug: "source-item") }
  let(:output) { create(:grid_item_definition, slug: "output-item") }

  describe "validations" do
    it "is valid with valid attributes" do
      yield_row = described_class.new(source_definition: source, output_definition: output, quantity: 2)
      expect(yield_row).to be_valid
    end

    it "requires quantity > 0" do
      yield_row = described_class.new(source_definition: source, output_definition: output, quantity: 0)
      expect(yield_row).not_to be_valid
      expect(yield_row.errors[:quantity]).to be_present
    end

    it "enforces unique source + output pair" do
      described_class.create!(source_definition: source, output_definition: output, quantity: 1)
      duplicate = described_class.new(source_definition: source, output_definition: output, quantity: 2)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:output_definition_id]).to include("already configured as a yield for this item")
    end
  end

  describe "associations" do
    it "belongs to source_definition" do
      yield_row = described_class.create!(source_definition: source, output_definition: output)
      expect(yield_row.source_definition).to eq(source)
    end

    it "belongs to output_definition" do
      yield_row = described_class.create!(source_definition: source, output_definition: output)
      expect(yield_row.output_definition).to eq(output)
    end
  end

  describe ".ordered" do
    it "orders by position then id" do
      y2 = described_class.create!(source_definition: source, output_definition: output, position: 1)
      output2 = create(:grid_item_definition, slug: "output-2")
      y1 = described_class.create!(source_definition: source, output_definition: output2, position: 0)

      expect(described_class.ordered.to_a).to eq([y1, y2])
    end
  end

  describe "dependent destroy from definition" do
    it "is destroyed when source definition is destroyed" do
      yield_row = described_class.create!(source_definition: source, output_definition: output)

      expect { source.destroy! }.to change(described_class, :count).by(-1)
      expect { yield_row.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
