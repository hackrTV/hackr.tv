require "rails_helper"

RSpec.describe TracksController, type: :request do
  # TracksController now only handles legacy redirects
  # All track viewing is handled by React SPA via pages#spa_root

  describe "Legacy redirects" do
    describe "GET /trackz" do
      it "redirects to thecyberpulse releases path" do
        get "/trackz"
        expect(response).to redirect_to("/thecyberpulse/releases")
        expect(response).to have_http_status(301)
      end
    end

    describe "GET /trackz/:id" do
      it "redirects to thecyberpulse track path" do
        get "/trackz/test-track"
        expect(response).to redirect_to("/thecyberpulse/trackz/test-track")
        expect(response).to have_http_status(301)
      end
    end
  end

  # SPA routes - individual track detail pages still exist
  describe "SPA routes" do
    describe "GET /thecyberpulse/trackz/:id" do
      it "renders the SPA root" do
        get "/thecyberpulse/trackz/test-track"
        expect(response).to have_http_status(:success)
        expect(response.body).to include('<div id="root">')
      end
    end

    describe "GET /xeraen/trackz/:id" do
      it "renders the SPA root" do
        get "/xeraen/trackz/xeraen-track"
        expect(response).to have_http_status(:success)
        expect(response.body).to include('<div id="root">')
      end
    end
  end
end
