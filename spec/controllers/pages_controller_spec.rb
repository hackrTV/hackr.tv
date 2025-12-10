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

    describe "GET /system_rot" do
      it "renders the SPA root" do
        get "/system_rot"
        expect(response).to have_http_status(:success)
        expect(response.body).to include('<div id="root">')
      end
    end

    describe "GET /wavelength_zero" do
      it "renders the SPA root" do
        get "/wavelength_zero"
        expect(response).to have_http_status(:success)
        expect(response.body).to include('<div id="root">')
      end
    end

    describe "GET /voiceprint" do
      it "renders the SPA root" do
        get "/voiceprint"
        expect(response).to have_http_status(:success)
        expect(response.body).to include('<div id="root">')
      end
    end

    describe "GET /temporal_blue_drift" do
      it "renders the SPA root" do
        get "/temporal_blue_drift"
        expect(response).to have_http_status(:success)
        expect(response.body).to include('<div id="root">')
      end
    end

    describe "GET /fm/radio" do
      it "renders the SPA root" do
        get "/fm/radio"
        expect(response).to have_http_status(:success)
        expect(response.body).to include('<div id="root">')
      end
    end

    describe "GET /fm/pulse_vault" do
      it "renders the SPA root" do
        get "/fm/pulse_vault"
        expect(response).to have_http_status(:success)
        expect(response.body).to include('<div id="root">')
      end
    end

    describe "GET /fm/bands" do
      it "renders the SPA root" do
        get "/fm/bands"
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
