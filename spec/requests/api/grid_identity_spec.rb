require "rails_helper"

RSpec.describe "Api::Grid identity", type: :request do
  let(:hackr) { create(:grid_hackr) }

  def login_as(h)
    post "/api/grid/login", params: {hackr_alias: h.hackr_alias, password: "hackthegrid"}, as: :json
  end

  describe "PATCH /api/grid/identity" do
    it "requires login" do
      patch "/api/grid/identity", params: {bio: "hello"}, as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "updates the bio" do
      login_as(hackr)
      patch "/api/grid/identity", params: {bio: "Operative on the wire."}, as: :json
      expect(response).to have_http_status(:ok)
      expect(hackr.reload.bio).to eq("Operative on the wire.")
      expect(response.parsed_body["hackr"]["bio"]).to eq("Operative on the wire.")
    end

    it "rejects a profane bio via the GovCorp censor" do
      login_as(hackr)
      patch "/api/grid/identity", params: {bio: "This is bullshit"}, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to start_with("GOVCORP CENSOR:")
    end

    it "rejects a bio over the length cap" do
      login_as(hackr)
      patch "/api/grid/identity", params: {bio: "x" * 513}, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects a bio containing an email address" do
      login_as(hackr)
      patch "/api/grid/identity", params: {bio: "reach me at ops@hackr.tv"}, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to match(/email/i)
    end

    it "still allows @mentions (which are not emails)" do
      login_as(hackr)
      patch "/api/grid/identity", params: {bio: "shouting out @xeraen"}, as: :json
      expect(response).to have_http_status(:ok)
    end
  end
end
