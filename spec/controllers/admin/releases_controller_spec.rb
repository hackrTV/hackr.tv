require "rails_helper"

RSpec.describe Admin::ReleasesController, type: :controller do
  let(:admin_hackr) { create(:grid_hackr, role: "admin") }
  let(:artist) { create(:artist) }

  before do
    session[:grid_hackr_id] = admin_hackr.id
  end

  describe "GET #index" do
    it "returns success" do
      get :index
      expect(response).to have_http_status(:ok)
    end

    it "loads releases with artists" do
      release = create(:release, artist: artist)

      get :index

      expect(assigns(:releases)).to include(release)
    end

    it "orders releases by artist name then release date" do
      artist_z = create(:artist, name: "Zebra")
      artist_a = create(:artist, name: "Alpha")

      create(:release, artist: artist_z, release_date: Date.today)
      release_a = create(:release, artist: artist_a, release_date: Date.today)

      get :index

      expect(assigns(:releases).to_a.first).to eq(release_a)
    end
  end

  describe "authentication" do
    before do
      session[:grid_hackr_id] = nil
    end

    it "redirects non-admin users to grid" do
      get :index
      expect(response).to redirect_to(grid_path)
    end

    it "redirects regular users to grid" do
      regular_user = create(:grid_hackr, role: "operative")
      session[:grid_hackr_id] = regular_user.id

      get :index
      expect(response).to redirect_to(grid_path)
    end
  end
end
