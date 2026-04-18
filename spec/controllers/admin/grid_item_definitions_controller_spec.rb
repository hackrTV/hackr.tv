require "rails_helper"

RSpec.describe Admin::GridItemDefinitionsController, type: :controller do
  let(:admin_hackr) { create(:grid_hackr, :admin) }

  before { session[:grid_hackr_id] = admin_hackr.id }

  describe "DELETE #destroy" do
    let!(:definition) { create(:grid_item_definition, slug: "test-item", name: "Test Item") }

    context "when definition has no references" do
      it "deletes the definition" do
        expect {
          delete :destroy, params: {id: definition.slug}
        }.to change(GridItemDefinition, :count).by(-1)
      end
    end

    context "when definition has live items" do
      before { GridItem.create!(definition.item_attributes.merge(grid_hackr: admin_hackr)) }

      it "refuses to delete" do
        expect {
          delete :destroy, params: {id: definition.slug}
        }.not_to change(GridItemDefinition, :count)
        expect(flash[:error]).to include("live items or shop listings")
      end
    end

    context "when definition is referenced as a salvage yield output" do
      let!(:source_def) { create(:grid_item_definition, slug: "source-item", name: "Source Item") }

      before do
        GridSalvageYield.create!(source_definition: source_def, output_definition: definition, quantity: 1)
      end

      it "refuses to delete" do
        expect {
          delete :destroy, params: {id: definition.slug}
        }.not_to change(GridItemDefinition, :count)
        expect(flash[:error]).to include("salvage yield output")
      end
    end
  end
end
