require "rails_helper"

RSpec.describe PagesController, type: :request do
  # All page routes now render the React SPA shell
  # Content is loaded client-side via React Router and API endpoints

  describe "SPA routes" do
    describe "GET /" do
      it "renders the SPA root" do
        get "/"
        expect(response).to have_http_status(:success)
        expect(response.body).to include('<div id="root">')
      end
    end

    describe "GET /thecyberpulse" do
      it "renders the SPA root" do
        get "/thecyberpulse"
        expect(response).to have_http_status(:success)
        expect(response.body).to include('<div id="root">')
      end
    end

    describe "GET /xeraen" do
      it "renders the SPA root" do
        get "/xeraen"
        expect(response).to have_http_status(:success)
        expect(response.body).to include('<div id="root">')
      end
    end

    describe "GET /sector/x" do
      it "renders the SPA root" do
        get "/sector/x"
        expect(response).to have_http_status(:success)
        expect(response.body).to include('<div id="root">')
      end
    end

    describe "GET /:band_slug (band profile routes)" do
      it "renders the SPA root for valid band slugs" do
        %w[system-rot wavelength-zero voiceprint temporal-blue-drift].each do |slug|
          get "/#{slug}"
          expect(response).to have_http_status(:success)
          expect(response.body).to include('<div id="root">')
        end
      end
    end

    describe "GET /fm/radio" do
      it "renders the SPA root" do
        get "/fm/radio"
        expect(response).to have_http_status(:success)
        expect(response.body).to include('<div id="root">')
      end
    end

    describe "GET /fm/pulse-vault" do
      it "renders the SPA root" do
        get "/fm/pulse-vault"
        expect(response).to have_http_status(:success)
        expect(response.body).to include('<div id="root">')
      end
    end

    describe "GET /f/net" do
      it "renders the SPA root" do
        get "/f/net"
        expect(response).to have_http_status(:success)
        expect(response.body).to include('<div id="root">')
      end
    end

    describe "GET /logs" do
      it "renders the SPA root" do
        get "/logs"
        expect(response).to have_http_status(:success)
        expect(response.body).to include('<div id="root">')
      end
    end
  end
end
