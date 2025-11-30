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

  describe "GET #new" do
    it "returns success" do
      get :new
      expect(response).to have_http_status(:ok)
    end

    it "builds a new scene" do
      get :new
      expect(assigns(:scene)).to be_a_new(OverlayScene)
    end

    it "loads available elements" do
      element = create(:overlay_element, active: true)
      get :new
      expect(assigns(:available_elements)).to include(element)
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        overlay_scene: {
          name: "New Scene",
          slug: "new-scene",
          scene_type: "fullscreen",
          width: 1920,
          height: 1080
        }
      }
    end

    it "creates a new scene" do
      expect {
        post :create, params: valid_params
      }.to change(OverlayScene, :count).by(1)
    end

    it "redirects to index on success" do
      post :create, params: valid_params
      expect(response).to redirect_to(admin_overlay_scenes_path)
    end

    it "sets success flash" do
      post :create, params: valid_params
      expect(flash[:success]).to include("New Scene")
    end

    it "renders new on failure" do
      invalid_params = {overlay_scene: {name: ""}}
      post :create, params: invalid_params
      expect(response).to have_http_status(:unprocessable_content)
      expect(response).to render_template(:new)
    end

    it "loads available elements on failure" do
      element = create(:overlay_element, active: true)
      invalid_params = {overlay_scene: {name: ""}}
      post :create, params: invalid_params
      expect(assigns(:available_elements)).to include(element)
    end
  end

  describe "GET #edit" do
    let(:scene) { create(:overlay_scene) }

    it "returns success" do
      get :edit, params: {id: scene.slug}
      expect(response).to have_http_status(:ok)
    end

    it "loads the scene" do
      get :edit, params: {id: scene.slug}
      expect(assigns(:scene)).to eq(scene)
    end

    it "loads available elements" do
      element = create(:overlay_element, active: true)
      get :edit, params: {id: scene.slug}
      expect(assigns(:available_elements)).to include(element)
    end
  end

  describe "PATCH #update" do
    let(:scene) { create(:overlay_scene, name: "Old Name") }

    it "updates the scene" do
      patch :update, params: {
        id: scene.slug,
        overlay_scene: {name: "New Name"}
      }

      scene.reload
      expect(scene.name).to eq("New Name")
    end

    it "redirects to index on success" do
      patch :update, params: {
        id: scene.slug,
        overlay_scene: {name: "New Name"}
      }
      expect(response).to redirect_to(admin_overlay_scenes_path)
    end

    it "sets success flash" do
      patch :update, params: {
        id: scene.slug,
        overlay_scene: {name: "New Name"}
      }
      expect(flash[:success]).to include("New Name")
    end

    it "renders edit on failure" do
      patch :update, params: {
        id: scene.slug,
        overlay_scene: {name: ""}
      }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response).to render_template(:edit)
    end
  end

  describe "DELETE #destroy" do
    let!(:scene) { create(:overlay_scene) }

    it "destroys the scene" do
      expect {
        delete :destroy, params: {id: scene.slug}
      }.to change(OverlayScene, :count).by(-1)
    end

    it "redirects to index" do
      delete :destroy, params: {id: scene.slug}
      expect(response).to redirect_to(admin_overlay_scenes_path)
    end

    it "sets success flash" do
      name = scene.name
      delete :destroy, params: {id: scene.slug}
      expect(flash[:success]).to include(name)
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
