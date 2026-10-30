require "rails_helper"

# /root/tracks — the tracks ledger (grouped by release, filterable) and
# the track record as console screens (admin/music/*, root_console.css;
# 2026-10-30): lyrics as one textarea, the audio file with a preview,
# // FREQUENCIES // as inputs, the release's other tracks for the hop.
RSpec.describe "Admin tracks", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }
  let(:xeraen) { create(:artist, :xeraen) }
  let(:release) { create(:release, artist: xeraen, name: "OMNIWAVE GENESIS", slug: "omniwave", release_type: "ep") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/tracks"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the tracks under one rule per release with the FILTER row, readouts and search haystacks" do
    create(:track, :with_audio, artist: xeraen, release: release, title: "Xordium", slug: "xordium", track_number: 1, featured: true)
    create(:track, artist: xeraen, release: release, title: "Encrypted Shroud", slug: "shroud", track_number: 2, show_in_pulse_vault: false)
    log_in!(admin)

    get "/root/tracks"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to include('data-controller="terminal ledger-filter"')
    expect(body).to include("FILTER")
    expect(body).to include('data-ledger-filter-target="input"')
    expect(body).to include("2 tracks")
    expect(body).to include("1 with audio · 1 in the vault · 1 featured · 1 release")
    expect(body).to include("// XERAEN · OMNIWAVE GENESIS (EP) //")
    expect(body).to include('data-ledger-filter-target="group"')
    expect(body).to include('data-search="xordium xordium xeraen omniwave genesis omniwave"')
    expect(body).to include("[01]")
    expect(body).to include("[02]")
    expect(body).to include("/root/tracks/shroud/edit")
    expect(body).to include("shroud · TRACK 02")
    expect(body).to include(">AUDIO<")
    expect(body).to include(">NO AUDIO<")
    expect(body).to include("type a track number")
  end

  it "prefills the release and the next track number on a new record" do
    create(:track, artist: xeraen, release: release, track_number: 1)
    create(:track, artist: xeraen, release: release, track_number: 4)
    log_in!(admin)

    get "/root/tracks/new", params: {release_id: release.id}

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to include(%(<option selected="selected" value="#{release.id}">OMNIWAVE GENESIS · EP</option>))
    expect(body).to include('name="track[track_number]"')
    expect(body).to include('value="5"')
    expect(body).to include("[&lt;] OMNIWAVE GENESIS")
    expect(body).to include("/root/releases/omniwave/edit")
  end

  it "creates a track on its release's artist and opens the track's own record" do
    log_in!(admin)

    expect {
      post "/root/tracks", params: {track: {title: "New Signal", slug: "new-signal", release_id: release.id, track_number: 1,
                                            streaming_links: {spotify: "https://open.spotify.com/track/x", youtube: ""}}}
    }.to change(Track, :count).by(1)

    track = Track.find_by!(slug: "new-signal")
    expect(track.artist).to eq(xeraen)
    expect(track.streaming_links).to eq({"spotify" => "https://open.spotify.com/track/x"})
    expect(response).to redirect_to("/root/tracks/new-signal/edit")
  end

  it "renders the record screen: fields, the audio on file with its purge, lyrics, frequencies, siblings and the public link" do
    create(:track, :with_audio, artist: xeraen, release: release, title: "Xordium", slug: "xordium", track_number: 1,
      duration: "3:45", featured: true, lyrics: "Line one\nLine two\n\n[Chorus]\nLine three",
      streaming_links: {"youtube" => "https://youtube.com/watch?v=abc"})
    create(:track, artist: xeraen, release: release, title: "Encrypted Shroud", slug: "shroud", track_number: 2, duration: "4:01")
    log_in!(admin)

    get "/root/tracks/xordium/edit"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to include('value="Xordium"')
    expect(body).to include("XERAEN · OMNIWAVE GENESIS · TRACK 01 · /root/tracks/xordium")
    expect(body).to include("★ FEATURED")
    expect(body).to include('action="/root/tracks/xordium"')
    expect(body).to include("[&lt;] OMNIWAVE GENESIS")
    expect(body).to include('href="/xeraen/trackz/xordium"') # [>] PUBLIC
    expect(body).to include(">ON FILE<")
    expect(body).to include("<audio")
    expect(body).to include('form="purge-audio"')
    expect(body).to include("/root/tracks/xordium/purge_audio")
    expect(body).to include("// DECODED LYRICS //")
    expect(body).to include("Line one\nLine two\n\n[Chorus]\nLine three")
    expect(body).to include('data-controller="autogrow"')
    expect(body).to include('name="track[streaming_links][youtube]"')
    expect(body).to include('value="https://youtube.com/watch?v=abc"')
    expect(body).to include("// ALSO ON OMNIWAVE GENESIS //")
    expect(body).to include("Encrypted Shroud")
    expect(body).to include('data-command="02"')
    expect(body).to include("/root/tracks/shroud/edit")
    expect(body).to include('form="delete-track"')
    expect(body).to include('id="delete-track"')
  end

  it "saves lyrics and frequencies and stays on the track; the artist follows a changed release" do
    track = create(:track, artist: xeraen, release: release, slug: "xordium", lyrics: nil)
    tcp = create(:artist, :thecyberpulse)
    other = create(:release, artist: tcp, name: "Dark Archive", slug: "dark-archive")
    log_in!(admin)

    patch "/root/tracks/xordium", params: {track: {title: track.title, slug: "xordium", release_id: other.id,
                                                   lyrics: "New lyrics", streaming_links: {spotify: "", bandcamp: "https://x.bandcamp.com/t"}}}

    expect(response).to redirect_to("/root/tracks/xordium/edit")
    track.reload
    expect(track.lyrics).to eq("New lyrics")
    expect(track.streaming_links).to eq({"bandcamp" => "https://x.bandcamp.com/t"})
    expect(track.release).to eq(other)
    expect(track.artist).to eq(tcp)
    follow_redirect!
    expect(response.body).to include("[OK]")
    expect(response.body).to include("The.CyberPul.se · Dark Archive")
  end

  it "re-renders a rejected save against the saved slug" do
    create(:track, artist: xeraen, release: release, slug: "xordium")
    log_in!(admin)

    patch "/root/tracks/xordium", params: {track: {title: "", slug: ""}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]")
    expect(response.body).to include('action="/root/tracks/xordium"')
    expect(response.body).to include("// ALSO ON OMNIWAVE GENESIS //").or include("// DECODED LYRICS //")
  end

  it "redirects show to the record screen, purges audio and deletes back to the release" do
    track = create(:track, :with_audio, artist: xeraen, release: release, slug: "xordium")
    log_in!(admin)

    get "/root/tracks/xordium"
    expect(response).to redirect_to("/root/tracks/xordium/edit")

    delete "/root/tracks/xordium/purge_audio"
    expect(response).to redirect_to("/root/tracks/xordium/edit")
    expect(track.reload.audio_file).not_to be_attached

    delete "/root/tracks/xordium"
    expect(response).to redirect_to("/root/releases/omniwave/edit")
    expect(Track.exists?(track.id)).to be(false)
  end
end
