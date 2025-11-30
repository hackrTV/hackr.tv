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

  describe "GET #new" do
    it "returns success" do
      get :new
      expect(response).to have_http_status(:ok)
    end

    it "builds a new element" do
      get :new
      expect(assigns(:element)).to be_a_new(OverlayElement)
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        overlay_element: {
          name: "New Element",
          slug: "new-element",
          element_type: "now_playing"
        }
      }
    end

    it "creates a new element" do
      expect {
        post :create, params: valid_params
      }.to change(OverlayElement, :count).by(1)
    end

    it "redirects to index on success" do
      post :create, params: valid_params
      expect(response).to redirect_to(admin_overlay_elements_path)
    end

    it "sets success flash" do
      post :create, params: valid_params
      expect(flash[:success]).to include("New Element")
    end

    it "renders new on failure" do
      invalid_params = {overlay_element: {name: ""}}
      post :create, params: invalid_params
      expect(response).to have_http_status(:unprocessable_content)
      expect(response).to render_template(:new)
    end
  end

  describe "GET #edit" do
    let(:element) { create(:overlay_element) }

    it "returns success" do
      get :edit, params: {id: element.slug}
      expect(response).to have_http_status(:ok)
    end

    it "loads the element" do
      get :edit, params: {id: element.slug}
      expect(assigns(:element)).to eq(element)
    end
  end

  describe "PATCH #update" do
    let(:element) { create(:overlay_element, name: "Old Name") }

    it "updates the element" do
      patch :update, params: {
        id: element.slug,
        overlay_element: {name: "New Name"}
      }

      element.reload
      expect(element.name).to eq("New Name")
    end

    it "redirects to index on success" do
      patch :update, params: {
        id: element.slug,
        overlay_element: {name: "New Name"}
      }
      expect(response).to redirect_to(admin_overlay_elements_path)
    end

    it "sets success flash" do
      patch :update, params: {
        id: element.slug,
        overlay_element: {name: "New Name"}
      }
      expect(flash[:success]).to include("New Name")
    end

    it "renders edit on failure" do
      patch :update, params: {
        id: element.slug,
        overlay_element: {name: ""}
      }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response).to render_template(:edit)
    end
  end

  describe "DELETE #destroy" do
    context "when element is not used in any scene" do
      let!(:element) { create(:overlay_element) }

      it "destroys the element" do
        expect {
          delete :destroy, params: {id: element.slug}
        }.to change(OverlayElement, :count).by(-1)
      end

      it "redirects to index" do
        delete :destroy, params: {id: element.slug}
        expect(response).to redirect_to(admin_overlay_elements_path)
      end

      it "sets success flash" do
        name = element.name
        delete :destroy, params: {id: element.slug}
        expect(flash[:success]).to include(name)
      end
    end

    context "when element is used in scenes" do
      let!(:element) { create(:overlay_element) }
      let!(:scene) { create(:overlay_scene) }

      before do
        create(:overlay_scene_element, overlay_scene: scene, overlay_element: element)
      end

      it "does not destroy the element" do
        expect {
          delete :destroy, params: {id: element.slug}
        }.not_to change(OverlayElement, :count)
      end

      it "sets error flash" do
        delete :destroy, params: {id: element.slug}
        expect(flash[:error]).to include("Cannot delete")
        expect(flash[:error]).to include("1 scene")
      end
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
