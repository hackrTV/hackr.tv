require "rails_helper"

# /root/radio_stations and /root/zone_playlists — the YAML-seeded,
# read-only music rotations as console readouts (console-ui-for-all-admin
# Phase 1, 2026-10-31).
RSpec.describe "Admin radio stations and zone playlists", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)

    get "/root/radio_stations"
    expect(response).not_to have_http_status(:ok)
    get "/root/zone_playlists"
    expect(response).not_to have_http_status(:ok)
  end

  it "lists the stations in dial order and opens one with its playlists" do
    station = create(:radio_station, name: "Pulse FM", slug: "pulse-fm", position: 0, genre: "Synthwave")
    create(:radio_station, name: "Dead Air", slug: "dead-air", position: 1, hidden: true)
    playlist = create(:playlist, name: "Night Drive")
    RadioStationPlaylist.create!(radio_station: station, playlist: playlist, position: 1)
    log_in!(admin)

    get "/root/radio_stations"
    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include("2 stations", "1 hidden", "[01]", "[02]", 'data-command="01"')
    expect(body).to include("pulse-fm · POS 0 · Synthwave", "ON THE DIAL", "HIDDEN", "1 playlist")
    expect(body).to include("read-only here")
    expect(body).not_to include("[RADIO]")
    expect(body).to include("[PLAYLISTS]", "type a station number")

    get "/root/radio_stations/#{station.id}"
    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include("Pulse FM", "pulse-fm", "http://example.com/stream", "// PLAYLISTS //", "Night Drive")
  end

  it "lists the zone playlists and opens one with its tracks in play order" do
    playlist = ZonePlaylist.create!(name: "Sprawl Ambience", slug: "sprawl", crossfade_duration_ms: 4000, default_volume: 0.4)
    first = create(:track, title: "Neon Rain")
    second = create(:track, title: "Static Bloom")
    ZonePlaylistTrack.create!(zone_playlist: playlist, track: second, position: 2)
    ZonePlaylistTrack.create!(zone_playlist: playlist, track: first, position: 1)
    log_in!(admin)

    get "/root/zone_playlists"
    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include("1 playlist", "2 tracks placed", "[01]", "4000 ms fade", "40% vol")
    expect(body).to include("/root/zone_playlists/#{playlist.id}")
    expect(body).not_to include("[PLAYLISTS]")

    get "/root/zone_playlists/#{playlist.id}"
    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include("Sprawl Ambience", "// TRACKS (2) //", "[01]", "[02]")
    expect(body.index("Neon Rain")).to be < body.index("Static Bloom")
    expect(body).to include("/root/tracks/#{first.slug}/edit")
  end
end
