require "rails_helper"

RSpec.describe "Artists API", type: :request do
  describe "GET /api/artists" do
    it "lists bands in the roster order: positioned first, then by name" do
      create(:artist, name: "alpha", slug: "alpha")
      create(:artist, name: "Bravo", slug: "bravo")
      create(:artist, name: "Zulu", slug: "zulu", position: 1)
      create(:artist, name: "Score", slug: "score", artist_type: "ost", position: 0)

      get "/api/artists"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.map { |artist| artist["slug"] }).to eq(%w[zulu alpha bravo])
    end
  end
end
