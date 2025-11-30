require "rails_helper"

RSpec.describe Admin::OverlaySceneElementsController, type: :controller do
  let(:admin_hackr) { create(:grid_hackr, role: "admin") }
  let(:scene) { create(:overlay_scene) }
  let(:element) { create(:overlay_element) }

  before do
    session[:grid_hackr_id] = admin_hackr.id
  end

  describe "GET #new" do
    it "returns success" do
      get :new, params: {overlay_scene_id: scene.slug}
      expect(response).to have_http_status(:ok)
    end

    it "builds a new scene element" do
      get :new, params: {overlay_scene_id: scene.slug}
      expect(assigns(:scene_element)).to be_a_new(OverlaySceneElement)
    end

    it "loads available elements" do
      active_element = create(:overlay_element, active: true)
      get :new, params: {overlay_scene_id: scene.slug}
      expect(assigns(:available_elements)).to include(active_element)
    end

    it "loads content options" do
      lower_third = create(:overlay_lower_third, active: true)
      ticker = create(:overlay_ticker, active: true)

      get :new, params: {overlay_scene_id: scene.slug}

      expect(assigns(:lower_thirds)).to include(lower_third)
      expect(assigns(:tickers)).to include(ticker)
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        overlay_scene_id: scene.slug,
        overlay_scene_element: {
          overlay_element_id: element.id,
          x: 100,
          y: 200,
          width: 400,
          height: 100,
          z_index: 1
        }
      }
    end

    it "creates a new scene element" do
      expect {
        post :create, params: valid_params
      }.to change(OverlaySceneElement, :count).by(1)
    end

    it "redirects to scene show on success" do
      post :create, params: valid_params
      expect(response).to redirect_to(admin_overlay_scene_path(scene))
    end

    it "sets success flash" do
      post :create, params: valid_params
      expect(flash[:success]).to include("Element added")
    end

    it "renders new on failure" do
      invalid_params = {
        overlay_scene_id: scene.slug,
        overlay_scene_element: {overlay_element_id: nil}
      }
      post :create, params: invalid_params
      expect(response).to have_http_status(:unprocessable_content)
      expect(response).to render_template(:new)
    end

    it "applies content overrides" do
      params_with_overrides = valid_params.merge(
        lower_third_slug: "host",
        max_items: "10"
      )

      post :create, params: params_with_overrides

      scene_element = OverlaySceneElement.last
      expect(scene_element.overrides["lower_third_slug"]).to eq("host")
      expect(scene_element.overrides["max_items"]).to eq(10)
    end
  end

  describe "GET #edit" do
    let!(:scene_element) { create(:overlay_scene_element, overlay_scene: scene, overlay_element: element) }

    it "returns success" do
      get :edit, params: {overlay_scene_id: scene.slug, id: scene_element.id}
      expect(response).to have_http_status(:ok)
    end

    it "loads the scene element" do
      get :edit, params: {overlay_scene_id: scene.slug, id: scene_element.id}
      expect(assigns(:scene_element)).to eq(scene_element)
    end

    it "loads available elements" do
      get :edit, params: {overlay_scene_id: scene.slug, id: scene_element.id}
      expect(assigns(:available_elements)).to include(element)
    end
  end

  describe "PATCH #update" do
    let!(:scene_element) { create(:overlay_scene_element, overlay_scene: scene, overlay_element: element, x: 0) }

    it "updates the scene element" do
      patch :update, params: {
        overlay_scene_id: scene.slug,
        id: scene_element.id,
        overlay_scene_element: {x: 500}
      }

      scene_element.reload
      expect(scene_element.x).to eq(500)
    end

    it "redirects to scene show on success" do
      patch :update, params: {
        overlay_scene_id: scene.slug,
        id: scene_element.id,
        overlay_scene_element: {x: 500}
      }
      expect(response).to redirect_to(admin_overlay_scene_path(scene))
    end

    it "sets success flash" do
      patch :update, params: {
        overlay_scene_id: scene.slug,
        id: scene_element.id,
        overlay_scene_element: {x: 500}
      }
      expect(flash[:success]).to include("Element updated")
    end

    it "applies content overrides on update" do
      patch :update, params: {
        overlay_scene_id: scene.slug,
        id: scene_element.id,
        overlay_scene_element: {x: 500},
        codex_entry_slug: "xeraen"
      }

      scene_element.reload
      expect(scene_element.overrides["codex_entry_slug"]).to eq("xeraen")
    end
  end

  describe "DELETE #destroy" do
    let!(:scene_element) { create(:overlay_scene_element, overlay_scene: scene, overlay_element: element) }

    it "destroys the scene element" do
      expect {
        delete :destroy, params: {overlay_scene_id: scene.slug, id: scene_element.id}
      }.to change(OverlaySceneElement, :count).by(-1)
    end

    it "redirects to scene show" do
      delete :destroy, params: {overlay_scene_id: scene.slug, id: scene_element.id}
      expect(response).to redirect_to(admin_overlay_scene_path(scene))
    end

    it "sets success flash" do
      delete :destroy, params: {overlay_scene_id: scene.slug, id: scene_element.id}
      expect(flash[:success]).to include("Element removed")
    end
  end

  describe "authentication" do
    before do
      session[:grid_hackr_id] = nil
    end

    it "redirects non-admin users" do
      get :new, params: {overlay_scene_id: scene.slug}
      expect(response).to redirect_to(grid_path)
    end
  end
end
