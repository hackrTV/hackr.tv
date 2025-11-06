require "rails_helper"

RSpec.describe PagesController, type: :request do
  describe "GET /" do
    it "returns http success" do
      get "/"
      expect(response).to have_http_status(:success)
    end

    it "displays content" do
      get "/"
      expect(response.body).to include("What is The.CyberPul.se?")
    end
  end

  describe "GET /xeraen" do
    it "returns http success" do
      get "/xeraen"
      expect(response).to have_http_status(:success)
    end

    it "displays XERAEN content" do
      get "/xeraen"
      expect(response.body).to include("Latest Release")
    end
  end

  describe "GET /xeraen/linkz" do
    it "returns http success" do
      get "/xeraen/linkz"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /sector/x" do
    it "returns http success" do
      get "/sector/x"
      expect(response).to have_http_status(:success)
    end
  end
end
