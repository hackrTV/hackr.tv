require "rails_helper"

RSpec.describe Api::GridController, type: :controller do
  describe "POST #register" do
    context "when prerelease mode is active" do
      before do
        # Stub APP_SETTINGS to have prerelease_mode set
        stub_const("APP_SETTINGS", {prerelease_mode: "alpha", prerelease_banner_text: "Test banner"}.freeze)
      end

      it "returns forbidden status" do
        post :register, params: {
          hackr_alias: "NewHackr",
          password: "password123",
          password_confirmation: "password123"
        }, format: :json

        expect(response).to have_http_status(:forbidden)
      end

      it "returns error message explaining registration is disabled" do
        post :register, params: {
          hackr_alias: "NewHackr",
          password: "password123",
          password_confirmation: "password123"
        }, format: :json

        json = JSON.parse(response.body)
        expect(json["success"]).to eq(false)
        expect(json["error"]).to include("Registration is temporarily disabled")
        expect(json["error"]).to include("alpha")
      end

      it "does not create a new GridHackr" do
        expect {
          post :register, params: {
            hackr_alias: "NewHackr",
            password: "password123",
            password_confirmation: "password123"
          }, format: :json
        }.not_to change(GridHackr, :count)
      end
    end

    context "when prerelease mode is not active" do
      before do
        # Stub APP_SETTINGS to have no prerelease_mode
        stub_const("APP_SETTINGS", {prerelease_mode: nil, prerelease_banner_text: nil}.freeze)
        # Create a starting room for registration
        zone = create(:grid_zone, slug: "hackr_tv_central")
        create(:grid_room, grid_zone: zone, room_type: "hub")
      end

      it "allows registration" do
        post :register, params: {
          hackr_alias: "NewHackr",
          password: "password123",
          password_confirmation: "password123"
        }, format: :json

        expect(response).to have_http_status(:created)
      end

      it "creates a new GridHackr" do
        expect {
          post :register, params: {
            hackr_alias: "NewHackr",
            password: "password123",
            password_confirmation: "password123"
          }, format: :json
        }.to change(GridHackr, :count).by(1)
      end

      it "returns success response with hackr data" do
        post :register, params: {
          hackr_alias: "NewHackr",
          password: "password123",
          password_confirmation: "password123"
        }, format: :json

        json = JSON.parse(response.body)
        expect(json["success"]).to eq(true)
        expect(json["hackr"]["hackr_alias"]).to eq("NewHackr")
      end

      it "rejects aliases shorter than minimum length" do
        post :register, params: {
          hackr_alias: "ABC",
          password: "password123",
          password_confirmation: "password123"
        }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(false)
        expect(json["error"]).to include("must be at least #{GridHackr::MINIMUM_ALIAS_LENGTH} characters")
      end

      it "rejects reserved aliases" do
        post :register, params: {
          hackr_alias: "administrator",
          password: "password123",
          password_confirmation: "password123"
        }, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(false)
        expect(json["error"]).to include("is reserved and cannot be used")
      end
    end
  end

  describe "POST #login" do
    let!(:hackr) { create(:grid_hackr, hackr_alias: "TestHackr", password: "password123") }

    context "when prerelease mode is active" do
      before do
        stub_const("APP_SETTINGS", {prerelease_mode: "alpha", prerelease_banner_text: "Test banner"}.freeze)
      end

      it "still allows login for existing users" do
        post :login, params: {
          hackr_alias: "TestHackr",
          password: "password123"
        }, format: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(true)
      end
    end
  end
end
