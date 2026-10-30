require "rails_helper"

# /root/releases — the releases ledger (grouped by artist) and the
# release record as console screens (admin/music/*, root_console.css;
# 2026-10-30): fields as status rows, // FREQUENCIES // as inputs, the
# // TRACKS // ledger with [DEL] buttons on hidden forms.
RSpec.describe "Admin releases", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }
  let(:xeraen) { create(:artist, :xeraen) }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/releases"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the releases under one rule per artist with LATEST / INCOMING readouts and state words" do
    tcp = create(:artist, :thecyberpulse)
    latest = create(:release, artist: xeraen, name: "OMNIWAVE GENESIS", slug: "omniwave", release_type: "ep", release_date: Date.new(2026, 10, 1))
    create(:release, artist: xeraen, name: "Signal Lock", slug: "signal-lock", coming_soon: true, release_date: nil)
    hidden = create(:release, artist: tcp, name: "Dark Archive", slug: "dark-archive", release_date: Date.new(2025, 1, 1))
    create(:track, artist: xeraen, release: latest, duration: "3:00")
    create(:track, artist: tcp, release: hidden, show_in_pulse_vault: false)
    log_in!(admin)

    get "/root/releases"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to include("// XERAEN · 2 RELEASES //")
    expect(body).to include("// THE.CYBERPUL.SE · 1 RELEASE //")
    expect(body).to include("3 releases")
    expect(body).to include("1 incoming")
    expect(body).to include("LATEST")
    expect(body).to include("INCOMING")
    expect(body).to include("PENDING TRANSMISSION")
    expect(body).to include("EP · 2026-10-01 · 1 track · 3:00 · omniwave")
    expect(body).to include(">LIVE<")
    expect(body).to include(">HIDDEN<")
    expect(body).to include("/root/releases/dark-archive/edit")
    expect(body).to include("[01]")
    expect(body).to include("[03]")
    expect(body).to include("type a release number")
  end

  it "prefills the artist on a new record and steps back to that artist" do
    log_in!(admin)

    get "/root/releases/new", params: {artist_id: xeraen.id}

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(%(<option selected="selected" value="#{xeraen.id}">XERAEN</option>))
    expect(response.body).to include("[&lt;] XERAEN")
    expect(response.body).to include("/root/artists/xeraen/edit")
  end

  it "creates a release keeping only the filled frequencies, and opens its record" do
    log_in!(admin)

    expect {
      post "/root/releases", params: {release: {
        name: "New Signal", slug: "new-signal", artist_id: xeraen.id, release_type: "single",
        streaming_links: {bandcamp: "", youtube: " https://youtube.com/watch?v=abc ", spotify: ""}
      }}
    }.to change(Release, :count).by(1)

    release = Release.find_by!(slug: "new-signal")
    expect(release.streaming_links).to eq({"youtube" => "https://youtube.com/watch?v=abc"})
    expect(response).to redirect_to("/root/releases/new-signal/edit")
    follow_redirect!
    expect(response.body).to include("[OK]")
    expect(response.body).to include("NO TRACKS ON THIS RELEASE")
  end

  it "stores nil when every frequency is blank (the public page aggregates the tracks' links)" do
    release = create(:release, artist: xeraen, slug: "omniwave", streaming_links: {"spotify" => "https://open.spotify.com/album/x"})
    log_in!(admin)

    patch "/root/releases/omniwave", params: {release: {name: release.name, slug: "omniwave", streaming_links: {spotify: "", youtube: ""}}}

    expect(response).to redirect_to("/root/releases/omniwave/edit")
    expect(release.reload.streaming_links).to be_nil
  end

  it "renders the record screen: fields, frequencies, prose, the tracks ledger with delete forms, cover purge and the public link" do
    release = create(:release, :with_cover, artist: xeraen, name: "OMNIWAVE GENESIS", slug: "omniwave", release_type: "ep",
      description: "A description.", credits: "Credits here.", notes: "Notes here.", catalog_number: "HFM-012",
      streaming_links: {"spotify" => "https://open.spotify.com/album/x"})
    one = create(:track, :with_audio, artist: xeraen, release: release, title: "Xordium", slug: "xordium", track_number: 1, duration: "3:45")
    two = create(:track, artist: xeraen, release: release, title: "Encrypted Shroud", slug: "shroud", track_number: 2, featured: true, show_in_pulse_vault: false)
    log_in!(admin)

    get "/root/releases/omniwave/edit"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to include('value="OMNIWAVE GENESIS"')
    expect(body).to include('value="HFM-012"')
    expect(body).to include("XERAEN · EP · /root/releases/omniwave")
    expect(body).to include('action="/root/releases/omniwave"')
    expect(body).to include("A description.")
    expect(body).to include("Credits here.")
    expect(body).to include("Notes here.")
    expect(body).to include("// FREQUENCIES //")
    expect(body).to include('name="release[streaming_links][spotify]"')
    expect(body).to include('value="https://open.spotify.com/album/x"')
    expect(body).to include('name="release[streaming_links][bandcamp]"')
    expect(body).to include("// TRACKS //")
    expect(body).to include("Xordium")
    expect(body).to include("Encrypted Shroud")
    expect(body).to include('data-command="01"')
    expect(body).to include("/root/tracks/xordium/edit")
    expect(body).to include(">AUDIO<")
    expect(body).to include(">NO AUDIO<")
    expect(body).to include(">★<")
    expect(body).to include(">VAULT<")
    expect(body).to include(">HIDDEN<")
    expect(body).to include(%(form="delete-track-#{one.id}"))
    expect(body).to include(%(id="delete-track-#{two.id}"))
    expect(body).to include("/root/tracks/new?release_id=#{release.id}")
    expect(body).to include('form="purge-cover"')
    expect(body).to include('id="purge-cover"')
    expect(body).to include("/root/releases/omniwave/purge_cover")
    expect(body).to include('data-controller="confirm-slug"')
    expect(body).to include('data-confirm-slug-slug-value="omniwave"')
    expect(body).to include('href="/xeraen/releases/omniwave"') # [>] PUBLIC
    expect(body).to include("/rails/active_storage/representations/redirect/")
    expect(body).to include('data-controller="peek"')
    expect(body).to include("[DELETE RELEASE + 2 TRACKS]")
  end

  it "re-renders a rejected save against the saved slug, without the cover purge for a bare record" do
    create(:release, artist: xeraen, slug: "omniwave")
    log_in!(admin)

    patch "/root/releases/omniwave", params: {release: {name: "", slug: ""}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]")
    expect(response.body).to include('action="/root/releases/omniwave"')
    expect(response.body).not_to include('form="purge-cover"')
  end

  it "redirects show to the record screen" do
    create(:release, artist: xeraen, slug: "omniwave")
    log_in!(admin)

    get "/root/releases/omniwave"

    expect(response).to redirect_to("/root/releases/omniwave/edit")
  end

  it "removes the cover and deletes a release with its tracks" do
    release = create(:release, :with_cover, artist: xeraen, slug: "omniwave")
    create(:track, artist: xeraen, release: release)
    log_in!(admin)

    delete "/root/releases/omniwave/purge_cover"
    expect(response).to redirect_to("/root/releases/omniwave/edit")
    expect(release.reload.cover_image).not_to be_attached

    expect { delete "/root/releases/omniwave" }.to change(Track, :count).by(-1)
    expect(response).to redirect_to("/root/releases")
    expect(Release.exists?(release.id)).to be(false)
  end
end
