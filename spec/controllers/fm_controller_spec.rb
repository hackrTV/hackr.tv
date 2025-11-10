require "rails_helper"

RSpec.describe FmController, type: :controller do
  describe "GET #index" do
    it "redirects to fm_radio_path" do
      get :index
      expect(response).to redirect_to(fm_radio_path)
    end
  end

  describe "GET #radio" do
    it "returns http success" do
      get :radio
      expect(response).to have_http_status(:success)
    end

    it "loads radio stations from config" do
      get :radio
      expect(assigns(:stations)).to be_present
      expect(assigns(:stations)).to be_an(Array)
    end
  end

  describe "GET #pulse_vault" do
    let!(:the_cyber_pulse) { create(:artist, name: "The.CyberPul.se") }
    let!(:xeraen) { create(:artist, name: "XERAEN") }
    let!(:other_artist_a) { create(:artist, name: "Artist A") }
    let!(:other_artist_z) { create(:artist, name: "Zulu Band") }

    let!(:tcp_album_new) { create(:album, artist: the_cyber_pulse, release_date: Date.new(2024, 6, 1)) }
    let!(:tcp_album_old) { create(:album, artist: the_cyber_pulse, release_date: Date.new(2023, 1, 1)) }
    let!(:xeraen_album) { create(:album, artist: xeraen, release_date: Date.new(2024, 3, 1)) }
    let!(:artist_a_album) { create(:album, artist: other_artist_a, release_date: Date.new(2024, 1, 1)) }
    let!(:artist_z_album) { create(:album, artist: other_artist_z, release_date: Date.new(2024, 2, 1)) }

    # The.CyberPul.se tracks - newer album first, then by track number
    let!(:tcp_new_track1) { create(:track, artist: the_cyber_pulse, album: tcp_album_new, track_number: 1, title: "TCP New 1") }
    let!(:tcp_new_track2) { create(:track, artist: the_cyber_pulse, album: tcp_album_new, track_number: 2, title: "TCP New 2") }
    let!(:tcp_old_track1) { create(:track, artist: the_cyber_pulse, album: tcp_album_old, track_number: 1, title: "TCP Old 1") }

    # XERAEN tracks
    let!(:xeraen_track1) { create(:track, artist: xeraen, album: xeraen_album, track_number: 1, title: "XERAEN 1") }
    let!(:xeraen_track2) { create(:track, artist: xeraen, album: xeraen_album, track_number: 2, title: "XERAEN 2") }

    # Other artists - alphabetically by artist name
    let!(:artist_a_track) { create(:track, artist: other_artist_a, album: artist_a_album, track_number: 1, title: "Artist A Track") }
    let!(:artist_z_track) { create(:track, artist: other_artist_z, album: artist_z_album, track_number: 1, title: "Zulu Track") }

    it "returns http success" do
      get :pulse_vault
      expect(response).to have_http_status(:success)
    end

    it "loads all tracks" do
      get :pulse_vault
      expect(assigns(:tracks)).to be_present
      expect(assigns(:tracks).count).to eq(7)
    end

    it "orders The.CyberPul.se tracks first" do
      get :pulse_vault
      tracks = assigns(:tracks)
      first_three = tracks.first(3)

      expect(first_three.map(&:artist).map(&:name).uniq).to eq(["The.CyberPul.se"])
    end

    it "orders XERAEN tracks second" do
      get :pulse_vault
      tracks = assigns(:tracks)
      tracks.select { |t| t.artist.name == "XERAEN" }

      # XERAEN tracks should be at positions 3 and 4 (0-indexed)
      expect(tracks[3].artist.name).to eq("XERAEN")
      expect(tracks[4].artist.name).to eq("XERAEN")
    end

    it "orders other artists alphabetically after XERAEN" do
      get :pulse_vault
      tracks = assigns(:tracks).to_a
      other_artists = tracks.last(2)

      expect(other_artists[0].artist.name).to eq("Artist A")
      expect(other_artists[1].artist.name).to eq("Zulu Band")
    end

    it "orders tracks by album release_date DESC within same artist" do
      get :pulse_vault
      tracks = assigns(:tracks)
      tcp_tracks = tracks.select { |t| t.artist.name == "The.CyberPul.se" }

      # Newer album (2024-06-01) should come before older album (2023-01-01)
      expect(tcp_tracks[0].album.release_date).to eq(Date.new(2024, 6, 1))
      expect(tcp_tracks[1].album.release_date).to eq(Date.new(2024, 6, 1))
      expect(tcp_tracks[2].album.release_date).to eq(Date.new(2023, 1, 1))
    end

    it "orders tracks by track_number ASC within same album" do
      get :pulse_vault
      tracks = assigns(:tracks)
      tcp_new_tracks = tracks.select { |t| t.album == tcp_album_new }

      expect(tcp_new_tracks[0].track_number).to eq(1)
      expect(tcp_new_tracks[1].track_number).to eq(2)
    end

    it "uses eager loading to avoid N+1 queries" do
      get :pulse_vault
      tracks = assigns(:tracks).to_a

      # Verify that associations are preloaded
      expect(tracks.first.association(:artist).loaded?).to be true
      expect(tracks.first.association(:album).loaded?).to be true
    end
  end

  describe "GET #bands" do
    let!(:artist1) { create(:artist, name: "Artist One") }
    let!(:artist2) { create(:artist, name: "Artist Two") }

    it "returns http success" do
      get :bands
      expect(response).to have_http_status(:success)
    end

    it "loads all artists ordered by name" do
      get :bands
      expect(assigns(:artists)).to eq([artist1, artist2])
    end
  end
end
