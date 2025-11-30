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

  describe "GET #new" do
    it "returns success" do
      get :new
      expect(response).to have_http_status(:ok)
    end

    it "builds a new lower third" do
      get :new
      expect(assigns(:lower_third)).to be_a_new(OverlayLowerThird)
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        overlay_lower_third: {
          name: "Host Intro",
          slug: "host-intro",
          primary_text: "John Doe",
          secondary_text: "Host"
        }
      }
    end

    it "creates a new lower third" do
      expect {
        post :create, params: valid_params
      }.to change(OverlayLowerThird, :count).by(1)
    end

    it "redirects to index on success" do
      post :create, params: valid_params
      expect(response).to redirect_to(admin_overlay_lower_thirds_path)
    end

    it "sets success flash" do
      post :create, params: valid_params
      expect(flash[:success]).to include("Host Intro")
    end

    it "renders new on failure" do
      invalid_params = {overlay_lower_third: {name: ""}}
      post :create, params: invalid_params
      expect(response).to have_http_status(:unprocessable_content)
      expect(response).to render_template(:new)
    end
  end

  describe "GET #edit" do
    let(:lower_third) { create(:overlay_lower_third) }

    it "returns success" do
      get :edit, params: {id: lower_third.slug}
      expect(response).to have_http_status(:ok)
    end

    it "loads the lower third" do
      get :edit, params: {id: lower_third.slug}
      expect(assigns(:lower_third)).to eq(lower_third)
    end
  end

  describe "PATCH #update" do
    let(:lower_third) { create(:overlay_lower_third, primary_text: "Old Text") }

    before do
      allow(ActionCable.server).to receive(:broadcast)
    end

    it "updates the lower third" do
      patch :update, params: {
        id: lower_third.slug,
        overlay_lower_third: {primary_text: "New Text"}
      }

      lower_third.reload
      expect(lower_third.primary_text).to eq("New Text")
    end

    it "broadcasts update" do
      expect_any_instance_of(OverlayLowerThird).to receive(:broadcast_update!)
      patch :update, params: {
        id: lower_third.slug,
        overlay_lower_third: {primary_text: "New Text"}
      }
    end

    it "redirects to index on success" do
      patch :update, params: {
        id: lower_third.slug,
        overlay_lower_third: {primary_text: "New Text"}
      }
      expect(response).to redirect_to(admin_overlay_lower_thirds_path)
    end

    it "sets success flash" do
      patch :update, params: {
        id: lower_third.slug,
        overlay_lower_third: {primary_text: "New Text"}
      }
      expect(flash[:success]).to include(lower_third.name)
    end

    it "renders edit on failure" do
      patch :update, params: {
        id: lower_third.slug,
        overlay_lower_third: {primary_text: ""}
      }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response).to render_template(:edit)
    end
  end

  describe "DELETE #destroy" do
    let!(:lower_third) { create(:overlay_lower_third) }

    it "destroys the lower third" do
      expect {
        delete :destroy, params: {id: lower_third.slug}
      }.to change(OverlayLowerThird, :count).by(-1)
    end

    it "redirects to index" do
      delete :destroy, params: {id: lower_third.slug}
      expect(response).to redirect_to(admin_overlay_lower_thirds_path)
    end

    it "sets success flash" do
      name = lower_third.name
      delete :destroy, params: {id: lower_third.slug}
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
