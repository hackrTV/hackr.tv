require "rails_helper"

RSpec.describe "ApplicationController redirects", type: :request do
  describe "CSRF protection" do
    let(:hackr) { create(:grid_hackr) }

    context "for API token requests" do
      before do
        hackr.generate_api_token!
      end

      it "allows requests with valid Bearer token without CSRF" do
        post "/api/pulses",
          params: {content: "Test pulse from CLI"},
          headers: {"Authorization" => "Bearer #{hackr.api_token}"},
          as: :json

        # Should not raise InvalidAuthenticityToken - request should be processed
        # May return other status based on pulse validation, but not 422 for CSRF
        expect(response.status).not_to eq(422)
      end

      it "returns unauthorized for invalid Bearer token" do
        post "/api/pulses",
          params: {content: "Test pulse"},
          headers: {"Authorization" => "Bearer invalid_token"},
          as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "database-backed redirects" do
    it "redirects from root path when redirect record exists" do
      create(:redirect, domain: "example.com", path: "/", destination_url: "https://destination.com")

      get "/", headers: {"Host" => "example.com"}
      expect(response).to redirect_to("https://destination.com")
    end

    it "redirects using global redirect (nil domain)" do
      create(:redirect, domain: nil, path: "/", destination_url: "https://global.com")

      get "/", headers: {"Host" => "anyhost.com"}
      expect(response).to redirect_to("https://global.com")
    end

    it "prefers domain-specific over global redirect" do
      create(:redirect, domain: nil, path: "/", destination_url: "https://global.com")
      create(:redirect, domain: "specific.com", path: "/", destination_url: "https://specific.com")

      get "/", headers: {"Host" => "specific.com"}
      expect(response).to redirect_to("https://specific.com")
    end

    it "does not redirect when no matching redirect" do
      get "/", headers: {"Host" => "localhost"}
      expect(response).not_to be_redirect
    end
  end

  describe "domain-based redirects" do
    context "xeraen domains" do
      it "redirects xeraen.com to hackr.tv/xeraen" do
        get "/", headers: {"Host" => "xeraen.com"}
        expect(response).to redirect_to("http://localhost:3000/xeraen/")
      end

      it "redirects rockerboy.net to hackr.tv/xeraen" do
        get "/", headers: {"Host" => "rockerboy.net"}
        expect(response).to redirect_to("http://localhost:3000/xeraen/")
      end

      it "preserves the path when redirecting" do
        get "/trackz", headers: {"Host" => "xeraen.com"}
        expect(response).to redirect_to("http://localhost:3000/xeraen/trackz")
      end
    end

    context "ashlinn domain" do
      it "redirects ashlinn.net to YouTube" do
        get "/", headers: {"Host" => "ashlinn.net"}
        expect(response).to redirect_to("https://youtube.com/AshlinnSnow")
      end
    end

    context "sector domains" do
      it "redirects sectorx.media to hackr.tv/sector/x" do
        get "/", headers: {"Host" => "sectorx.media"}
        expect(response).to redirect_to("http://localhost:3000/sector/x/")
      end
    end

    context "hackr.tv domain" do
      it "does not redirect hackr.tv" do
        get "/", headers: {"Host" => "hackr.tv"}
        expect(response).not_to be_redirect
      end
    end

    context "localhost development" do
      it "does not redirect localhost" do
        get "/", headers: {"Host" => "localhost"}
        expect(response).not_to be_redirect
      end
    end
  end

  describe "combined redirects" do
    it "checks database redirects before domain redirects" do
      create(:redirect, domain: "xeraen.com", path: "/", destination_url: "https://special.com")

      get "/", headers: {"Host" => "xeraen.com"}
      expect(response).to redirect_to("https://special.com")
    end
  end
end
