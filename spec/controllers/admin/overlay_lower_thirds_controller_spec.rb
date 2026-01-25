require "rails_helper"

RSpec.describe Admin::OverlayLowerThirdsController, type: :controller do
  let(:admin_hackr) { create(:grid_hackr, role: "admin") }

  before do
    session[:grid_hackr_id] = admin_hackr.id
  end

  describe "GET #index" do
    it "returns success" do
      get :index
      expect(response).to have_http_status(:ok)
    end

    it "loads lower thirds ordered by name" do
      lower_third = create(:overlay_lower_third)
      get :index
      expect(assigns(:lower_thirds)).to include(lower_third)
    end
  end

  describe "GET #show" do
    let(:lower_third) { create(:overlay_lower_third) }

    it "returns success" do
      get :show, params: {id: lower_third.slug}
      expect(response).to have_http_status(:ok)
    end

    it "loads the lower third by slug" do
      get :show, params: {id: lower_third.slug}
      expect(assigns(:lower_third)).to eq(lower_third)
    end
  end

  describe "authentication" do
    before do
      session[:grid_hackr_id] = nil
    end

    it "redirects non-admin users" do
      get :index
      expect(response).to redirect_to(grid_path)
    end
  end
end
