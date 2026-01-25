require "rails_helper"

RSpec.describe Admin::OverlayElementsController, type: :controller do
  let(:admin_hackr) { create(:grid_hackr, role: "admin") }

  before do
    session[:grid_hackr_id] = admin_hackr.id
  end

  describe "GET #index" do
    it "returns success" do
      get :index
      expect(response).to have_http_status(:ok)
    end

    it "loads elements ordered by type and name" do
      element = create(:overlay_element)
      get :index
      expect(assigns(:elements)).to include(element)
    end
  end

  describe "GET #show" do
    let(:element) { create(:overlay_element) }

    it "returns success" do
      get :show, params: {id: element.slug}
      expect(response).to have_http_status(:ok)
    end

    it "loads the element by slug" do
      get :show, params: {id: element.slug}
      expect(assigns(:element)).to eq(element)
    end

    it "loads scenes using this element" do
      scene = create(:overlay_scene)
      create(:overlay_scene_element, overlay_scene: scene, overlay_element: element)

      get :show, params: {id: element.slug}
      expect(assigns(:used_in_scenes)).to include(scene)
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
