require "rails_helper"

RSpec.describe Admin::OverlayScenesController, type: :controller do
  let(:admin_hackr) { create(:grid_hackr, role: "admin") }

  before do
    session[:grid_hackr_id] = admin_hackr.id
  end

  describe "GET #index" do
    it "returns success" do
      get :index
      expect(response).to have_http_status(:ok)
    end

    it "loads ordered scenes" do
      scene = create(:overlay_scene)
      get :index
      expect(assigns(:scenes)).to include(scene)
    end
  end

  describe "GET #show" do
    let(:scene) { create(:overlay_scene) }

    it "returns success" do
      get :show, params: {id: scene.slug}
      expect(response).to have_http_status(:ok)
    end

    it "loads the scene by slug" do
      get :show, params: {id: scene.slug}
      expect(assigns(:scene)).to eq(scene)
    end

    it "loads scene elements" do
      element = create(:overlay_element)
      scene_element = create(:overlay_scene_element, overlay_scene: scene, overlay_element: element)

      get :show, params: {id: scene.slug}
      expect(assigns(:elements)).to include(scene_element)
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
