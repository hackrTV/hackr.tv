require "rails_helper"

# /root/artists — the artists ledger and the artist record as console
# screens (admin/music/*, root_console.css; 2026-10-30).
RSpec.describe "Admin artists", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/artists"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the artists as numbered ledger rows with the catalog readouts, destinations and the prompt" do
    xeraen = create(:artist, :xeraen)
    create(:artist, name: "Night Static", slug: "night-static", artist_type: "ost", genre: nil)
    release = create(:release, artist: xeraen)
    create(:track, artist: xeraen, release: release)
    create(:release, artist: xeraen, slug: "incoming", coming_soon: true)
    log_in!(admin)

    get "/root/artists"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to include('class="console console--root"')
    expect(body).to include("2 artists")
    expect(body).to include("1 band · 1 ost · 0 voiceover")
    expect(body).to include("2 releases")
    expect(body).to include("1 incoming")
    expect(body).to include("[01]")
    expect(body).to include("[02]")
    expect(body).to include('data-command="01"')
    expect(body).to include("night-static · OST")
    expect(body).to include("xeraen · BAND · Industrial/Dark Synth")
    expect(body).to include("/root/artists/night-static/edit")
    expect(body).to include("[RELEASES]")
    expect(body).to include("[TRACKS]")
    expect(body).not_to include("[ARTISTS]")
    expect(body).to include("type an artist number")
    expect(body).to include('data-command="new"')
  end

  it "redirects show to the record screen" do
    artist = create(:artist, slug: "system-rot")
    log_in!(admin)

    get "/root/artists/system-rot"

    expect(response).to redirect_to("/root/artists/system-rot/edit")
    expect(artist.slug).to eq("system-rot")
  end

  it "renders the record screen with the fields, the releases ledger, a locked delete and the public link" do
    xeraen = create(:artist, :xeraen)
    release = create(:release, artist: xeraen, name: "OMNIWAVE GENESIS", slug: "omniwave", release_type: "ep")
    create(:track, artist: xeraen, release: release, show_in_pulse_vault: false)
    log_in!(admin)

    get "/root/artists/xeraen/edit"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to include('value="XERAEN"')
    expect(body).to include('action="/root/artists/xeraen"')
    expect(body).to include("// RELEASES //")
    expect(body).to include("OMNIWAVE GENESIS")
    expect(body).to include("HIDDEN") # every track vault-hidden
    expect(body).to include("/root/releases/omniwave/edit")
    expect(body).to include("/root/releases/new?artist_id=#{xeraen.id}")
    expect(body).to include("DELETE LOCKED")
    expect(body).not_to include('form="delete-artist"')
    expect(body).to include('href="/xeraen/releases"') # [>] PUBLIC — a routed slug
    expect(body).to include("[HISTORY]")
  end

  it "offers delete only while nothing references the artist, and hides PUBLIC for an unrouted slug" do
    create(:artist, slug: "fresh-act")
    log_in!(admin)

    get "/root/artists/fresh-act/edit"

    expect(response.body).to include('form="delete-artist"')
    expect(response.body).to include('id="delete-artist"')
    expect(response.body).not_to include("[>] PUBLIC")
  end

  it "saves the record and stays on it" do
    create(:artist, slug: "fresh-act", genre: nil)
    log_in!(admin)

    patch "/root/artists/fresh-act", params: {artist: {name: "Fresh Act", slug: "fresh-act", artist_type: "ost", genre: "Noise"}}

    expect(response).to redirect_to("/root/artists/fresh-act/edit")
    follow_redirect!
    expect(response.body).to include("[OK]")
    expect(response.body).to include(ERB::Util.html_escape("Artist 'Fresh Act' updated."))
    expect(Artist.find_by(slug: "fresh-act")).to have_attributes(artist_type: "ost", genre: "Noise")
  end

  it "re-renders a rejected save against the saved slug" do
    create(:artist, slug: "fresh-act")
    log_in!(admin)

    patch "/root/artists/fresh-act", params: {artist: {name: "", slug: ""}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]")
    expect(response.body).to include('action="/root/artists/fresh-act"')
    expect(response.body).to include("/root/artists/fresh-act/history")
  end

  it "creates an artist and opens its record" do
    log_in!(admin)

    expect {
      post "/root/artists", params: {artist: {name: "New Act", slug: "new-act", artist_type: "band"}}
    }.to change(Artist, :count).by(1)

    expect(response).to redirect_to("/root/artists/new-act/edit")
  end

  it "refuses to delete an artist with releases, and deletes an empty one" do
    held = create(:artist, slug: "held")
    create(:release, artist: held)
    empty = create(:artist, slug: "empty")
    log_in!(admin)

    delete "/root/artists/held"
    expect(response).to redirect_to("/root/artists/held/edit")
    expect(Artist.exists?(held.id)).to be(true)

    delete "/root/artists/empty"
    expect(response).to redirect_to("/root/artists")
    expect(Artist.exists?(empty.id)).to be(false)
  end
end
