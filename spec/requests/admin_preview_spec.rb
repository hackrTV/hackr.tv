require "rails_helper"

# Controlled-rollout gate (AdminPreview concern): WIRE + PULSE GRID are
# admin-only for now. Non-admins get the coming-soon page (HTML) or 403
# (JSON / turbo-stream); admins pass through and see the ADMIN PREVIEW
# banner. The underlying login/feature-grant gates keep their own specs
# — this file pins only the preview layer.
RSpec.describe "Admin preview gating", type: :request do
  let(:zone) { create(:grid_zone) }
  let(:room) { create(:grid_room, grid_zone: zone) }
  let!(:admin) do
    create(:grid_hackr, :admin, password: "hackthegrid", current_room: room,
      stats: {"tutorial_completed" => true})
  end
  let!(:hackr) { create(:grid_hackr, password: "hackthegrid") }

  def log_in!(as)
    post "/grid/login", params: {hackr_alias: as.hackr_alias, password: "hackthegrid"}
  end

  def turbo_stream_headers
    {"Accept" => "text/vnd.turbo-stream.html"}
  end

  describe "WIRE pages" do
    it "shows the coming-soon page to anonymous visitors" do
      get "/wire"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("The WIRE")
      expect(response.body).to include("will open soon")
      expect(response.body).not_to include("ADMIN PREVIEW")
    end

    it "shows the coming-soon page to logged-in non-admins" do
      log_in!(hackr)
      get "/wire"

      expect(response.body).to include("will open soon")
      expect(response.body).not_to include("wire-feed")
    end

    it "gates profile and single-pulse pages" do
      pulse = create(:pulse, grid_hackr: admin)
      log_in!(hackr)

      get "/wire/#{admin.hackr_alias.downcase}"
      expect(response.body).to include("will open soon")

      get "/wire/pulse/#{pulse.id}"
      expect(response.body).to include("will open soon")
    end

    it "renders the feed with the ADMIN PREVIEW banner for admins" do
      log_in!(admin)
      get "/wire"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ADMIN PREVIEW")
      expect(response.body).to include("admins only")
      expect(response.body).not_to include("will open soon")
    end

    it "blocks the form endpoints for non-admins" do
      log_in!(hackr)
      post "/wire/pulses", params: {content: "hello"}, headers: turbo_stream_headers

      expect(response).to have_http_status(:forbidden)
      expect(Pulse.count).to eq(0)
    end
  end

  describe "WIRE JSON API" do
    it "403s non-admins on the public read endpoints" do
      get "/api/pulses"
      expect(response).to have_http_status(:forbidden)

      get "/api/profiles/#{admin.hackr_alias.downcase}"
      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body["error"]).to match(/not opened/)
    end

    it "serves admins" do
      log_in!(admin)

      get "/api/pulses"
      expect(response).to have_http_status(:ok)

      get "/api/profiles/#{admin.hackr_alias.downcase}"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PULSE GRID pages" do
    it "still redirects anonymous visitors to login first" do
      get "/grid"

      expect(response).to redirect_to(%r{/grid/login})
    end

    it "shows the coming-soon page to non-admins even with the feature grant" do
      create(:feature_grant, grid_hackr: hackr, feature: FeatureGrant::PULSE_GRID)
      log_in!(hackr)
      get "/grid"

      expect(response.body).to include("will open soon")
    end

    it "blocks the command endpoint for granted non-admins" do
      create(:feature_grant, grid_hackr: hackr, feature: FeatureGrant::PULSE_GRID)
      log_in!(hackr)
      post "/grid/commands", params: {input: "look"}, headers: turbo_stream_headers

      expect(response).to have_http_status(:forbidden)
    end

    it "gates the meta pages" do
      create(:feature_grant, grid_hackr: hackr, feature: FeatureGrant::PULSE_GRID)
      log_in!(hackr)
      get "/achievements"

      expect(response.body).to include("will open soon")
    end

    it "gates the tactical surface" do
      create(:feature_grant, grid_hackr: hackr, feature: FeatureGrant::TACTICAL_GRID)
      log_in!(hackr)
      get "/grid/1337"

      expect(response.body).to include("will open soon")
    end

    it "lets admins into /grid with the banner" do
      log_in!(admin)
      get "/grid"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ADMIN PREVIEW")
    end

    it "403s granted non-admins on the JSON command API" do
      create(:feature_grant, grid_hackr: hackr, feature: FeatureGrant::PULSE_GRID)
      log_in!(hackr)
      post "/api/grid/command", params: {input: "look"}

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body["error"]).to match(/not opened/)
    end
  end
end
