require "rails_helper"

# admin/shared/version_history — every Versionable record's HISTORY as a
# console screen (Admin::Versionable#history; console-ui-for-all-admin
# Phase 0, 2026-10-30). Artists (slug-keyed, no children) and missions
# (objectives fold in as child rows) stand for the 26 resources.
RSpec.describe "Admin version history", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    create(:artist, slug: "fresh-act")
    log_in!(create(:grid_hackr, password: "hackthegrid"))

    get "/root/artists/fresh-act/history"

    expect(response).not_to have_http_status(:ok)
  end

  it "renders the record's versions as a numbered ledger: event, source, who, when and the diff lines" do
    create(:artist, slug: "fresh-act", name: "Fresh Act", genre: nil)
    log_in!(admin)
    patch "/root/artists/fresh-act", params: {artist: {name: "Fresher Act", slug: "fresh-act", artist_type: "band", genre: "Noise"}}

    get "/root/artists/fresh-act/history"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include('<h1 class="console-bar-title">Fresher Act</h1>')
    expect(body).to include("ROOT · ARTIST · HISTORY · fresh-act")
    expect(body).to include('data-command="back" href="/root/artists">[&lt;] BACK</a>')
    expect(body).to include('data-command="edit" href="/root/artists/fresh-act/edit">[EDIT]</a>')
    expect(body).to include("2 versions")
    expect(body).not_to include("child change")
    expect(body).to include("// VERSIONS //")
    expect(body).to include('<div class="rc-row rc-row--head" aria-hidden="true">')
    expect(body).to match(%r{\[01\]</span>\s*<span class="rc-cell rc-star">UPDATE</span>})
    expect(body).to match(%r{\[02\]</span>\s*<span class="rc-cell rc-on">CREATE</span>})
    expect(body).to include(%(<span class="rc-cell rc-hot">#{admin.hackr_alias}</span>)) # the update, through the request
    expect(body).to include('<span class="rc-cell rc-off">system</span>') # the factory's create
    expect(body).to include('<span class="rc-diff-key">name</span>:')
    expect(body).to include('<del class="rc-del">Fresh Act</del>')
    expect(body).to include("&gt;")
    expect(body).to include('<ins class="rc-add">Fresher Act</ins>')
    expect(body).to match(%r{<span class="rc-diff-key">genre</span>:\s*<ins class="rc-add">Noise</ins>}) # nil → Noise: no struck value
    expect(body).not_to include("<%") # the bar partial's comment stays a comment
    expect(body).to include("// END OF RECORD //")
    expect(body).to include('type <span class="console-dim">back</span> or <span class="console-dim">edit</span>')
  end

  it "shows a flag flipped off as true > false, not true > null" do
    xeraen = create(:artist, :xeraen)
    release = create(:release, artist: xeraen)
    track = create(:track, artist: xeraen, release: release, featured: true)
    log_in!(admin)
    patch "/root/tracks/#{track.slug}", params: {track: {featured: "0"}}
    patch "/root/tracks/#{track.slug}", params: {track: {featured: "1"}}

    get "/root/tracks/#{track.slug}/history"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to match(%r{<span class="rc-diff-key">featured</span>:\s*<del class="rc-del">true</del>\s*&gt;\s*<ins class="rc-add">false</ins>})
    expect(body).to match(%r{<span class="rc-diff-key">featured</span>:\s*<del class="rc-del">false</del>\s*&gt;\s*<ins class="rc-add">true</ins>})
    expect(body).not_to include('<span class="console-dim">null</span>')
  end

  it "folds a child's versions in, naming the child" do
    mission = create(:grid_mission, slug: "first-run", name: "First Run")
    create(:grid_mission_objective, grid_mission: mission, label: "Reach the node")
    log_in!(admin)

    get "/root/grid_missions/first-run/history"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to include('<h1 class="console-bar-title">First Run</h1>')
    expect(body).to include("1 child change")
    expect(body).to include('<span class="rc-cell rc-hot">Grid mission objective: Reach the node</span>')
    expect(body).to include('<span class="rc-diff-key">label</span>:')
    expect(body).to include('data-command="edit" href="/root/grid_missions/first-run/edit">[EDIT]</a>')
  end

  it "reads NO VERSIONS when tracking recorded nothing" do
    PaperTrail.request(enabled: false) { create(:artist, slug: "silent") }
    log_in!(admin)

    get "/root/artists/silent/history"

    expect(response.body).to include("0 versions")
    expect(response.body).to include("NO VERSIONS ON RECORD")
    expect(response.body).not_to include("rc-row--head")
  end
end
