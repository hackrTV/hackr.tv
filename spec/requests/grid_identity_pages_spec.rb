require "rails_helper"

# Server-rendered identity page (Hotwire migration Phase 2).
RSpec.describe "Grid identity pages", type: :request do
  let!(:hackr) { create(:grid_hackr, password: "hackthegrid", email: "op@example.com", bio: "Old bio") }

  def log_in!
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  describe "GET /grid/identity" do
    it "requires login" do
      get "/grid/identity"

      expect(response).to redirect_to("/grid/login")
    end

    it "renders profile fields and the three sections" do
      log_in!
      get "/grid/identity"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("HACKR SETTINGS")
      expect(response.body).to include(hackr.hackr_alias)
      expect(response.body).to include("op@example.com")
      expect(response.body).to include("Old bio")
      expect(response.body).to include("CHANGE EMAIL")
      expect(response.body).to include("TWO-FACTOR AUTHENTICATION")
      expect(response.body).to include("[ INACTIVE ]")
      expect(response.body).to include("RESET CREDENTIALS")
    end
  end

  describe "PATCH /grid/identity" do
    it "saves the bio and confirms" do
      log_in!

      patch "/grid/identity", params: {bio: "Broadcasting from the Fracture."}

      expect(response).to redirect_to("/grid/identity")
      expect(flash[:x_bio_notice]).to eq("Bio updated.")
      expect(hackr.reload.bio).to eq("Broadcasting from the Fracture.")
    end

    it "rejects a bio containing an email and re-renders with the error" do
      log_in!

      patch "/grid/identity", params: {bio: "mail me at op@example.com"}

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("can&#39;t contain an email address")
      expect(hackr.reload.bio).to eq("Old bio")
    end

    it "rejects a bio over 512 characters" do
      log_in!

      patch "/grid/identity", params: {bio: "x" * 513}

      expect(response).to have_http_status(:unprocessable_entity)
      expect(hackr.reload.bio).to eq("Old bio")
    end
  end
end
