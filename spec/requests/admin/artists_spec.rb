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
    expect(body).to include('name="artist[profile_path]"', "// DESCRIPTION //", 'name="artist[description]"')
    expect(body).to include('name="artist[avatar]"', "[^] UPLOAD AVATAR", 'name="artist[hero_image]"', "[^] UPLOAD IMAGE")
    expect(body).not_to include('form="purge-avatar"', 'form="purge-hero-image"')
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

    attrs = {name: "Fresh Act", slug: "fresh-act", artist_type: "ost", genre: "Noise", profile_path: " /fresh-act ", description: "Noise since {year}."}
    patch "/root/artists/fresh-act", params: {artist: attrs}

    expect(response).to redirect_to("/root/artists/fresh-act/edit")
    follow_redirect!
    expect(response.body).to include("[OK]")
    expect(response.body).to include(ERB::Util.html_escape("Artist 'Fresh Act' updated."))
    expect(Artist.find_by(slug: "fresh-act")).to have_attributes(artist_type: "ost", genre: "Noise",
      profile_path: "/fresh-act", description: "Noise since {year}.")
  end

  it "uploads, shows and purges the avatar and the artist image" do
    create(:artist, slug: "fresh-act", name: "Fresh Act")
    log_in!(admin)

    get "/root/artists"
    expect(response.body).to include('class="rc-row rc-row--avatar"', "cc-cover-none")

    images = {avatar: fixture_file_upload("test_cover.jpg", "image/jpeg"), hero_image: fixture_file_upload("test_cover.jpg", "image/jpeg")}
    patch "/root/artists/fresh-act", params: {artist: images}
    expect(response).to redirect_to("/root/artists/fresh-act/edit")
    artist = Artist.find_by(slug: "fresh-act")
    expect(artist.avatar).to be_attached
    expect(artist.hero_image).to be_attached

    follow_redirect!
    body = response.body
    expect(body).to include("[^] REPLACE AVATAR", "[^] REPLACE IMAGE", 'class="cc-art-img"')
    expect(body).to include('form="purge-avatar"', 'id="purge-avatar"', "/root/artists/fresh-act/purge_avatar")
    expect(body).to include('form="purge-hero-image"', 'id="purge-hero-image"', "/root/artists/fresh-act/purge_hero_image")

    get "/root/artists"
    expect(response.body).to include('class="cc-cover-img"')

    delete "/root/artists/fresh-act/purge_avatar"
    expect(response).to redirect_to("/root/artists/fresh-act/edit")
    expect(artist.reload.avatar).not_to be_attached
    expect(artist.hero_image).to be_attached

    delete "/root/artists/fresh-act/purge_hero_image"
    expect(response).to redirect_to("/root/artists/fresh-act/edit")
    expect(artist.reload.hero_image).not_to be_attached
  end

  it "refuses an avatar that is not an image and re-renders without a preview" do
    create(:artist, slug: "fresh-act", name: "Fresh Act")
    log_in!(admin)

    patch "/root/artists/fresh-act", params: {artist: {avatar: fixture_file_upload("test_audio.mp3", "audio/mpeg")}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]", "Avatar must be a JPEG, PNG, or WebP image", "[^] UPLOAD AVATAR")
    expect(Artist.find_by(slug: "fresh-act").avatar).not_to be_attached
  end

  it "refuses a profile path that is not absolute, and blanks one back to nil" do
    create(:artist, slug: "fresh-act", profile_path: "/fresh-act")
    log_in!(admin)

    patch "/root/artists/fresh-act", params: {artist: {profile_path: "fresh-act"}}
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]", "Profile path is invalid")
    expect(Artist.find_by(slug: "fresh-act").profile_path).to eq("/fresh-act")

    patch "/root/artists/fresh-act", params: {artist: {profile_path: ""}}
    expect(response).to redirect_to("/root/artists/fresh-act/edit")
    expect(Artist.find_by(slug: "fresh-act").profile_path).to be_nil
  end

  it "saves a position from the record's POSITION row and prints it on the ledger" do
    create(:artist, slug: "fresh-act", name: "Fresh Act")
    create(:artist, slug: "loose-act", name: "Loose Act")
    log_in!(admin)

    get "/root/artists/fresh-act/edit"
    expect(response.body).to include('name="artist[position]"')

    patch "/root/artists/fresh-act", params: {artist: {position: "3"}}
    expect(response).to redirect_to("/root/artists/fresh-act/edit")
    expect(Artist.find_by(slug: "fresh-act").position).to eq(3)

    get "/root/artists"
    expect(response.body).to include("fresh-act · BAND · Electronic · POS 3")
    expect(response.body).to include("loose-act · BAND · Electronic</div>")

    patch "/root/artists/fresh-act", params: {artist: {position: "-1"}}
    expect(response).to have_http_status(:unprocessable_entity)
    expect(Artist.find_by(slug: "fresh-act").position).to eq(3)
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
