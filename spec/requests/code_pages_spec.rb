require "rails_helper"

# Server-rendered code browser (Hotwire migration Phase 1). Login-gated;
# rouge replaces highlight.js. RepoReaderService is stubbed (no cloned
# repos on disk in test).
RSpec.describe "Code pages", type: :request do
  let(:hackr) { create(:grid_hackr, password: "hackthegrid") }

  def log_in
    post "/api/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "redirects anonymous visitors to the grid login" do
    get "/code"
    expect(response).to redirect_to("/grid/login")
  end

  it "renders the repo index with language filters and search haystacks" do
    create(:code_repository, name: "relay", slug: "relay", language: "Go", description: "Chat aggregator")
    create(:code_repository, name: "synthia", slug: "synthia", language: "Ruby")
    create(:code_repository, :hidden, name: "secret-repo", slug: "secret-repo")

    log_in
    get "/code"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("relay")
    expect(response.body).to include("Chat aggregator")
    expect(response.body).not_to include("secret-repo")
    expect(response.body).to include('data-language="Go"')
    expect(response.body).to include('data-search="relay chat aggregator"')
  end

  it "renders a repo root tree" do
    repo = create(:code_repository, slug: "relay")
    allow_any_instance_of(CodeRepository).to receive(:cloned?).and_return(true)
    allow_any_instance_of(Code::RepoReaderService).to receive(:tree).and_return([
      {name: "cmd", path: "cmd", type: "tree"},
      {name: "main.go", path: "main.go", type: "blob"}
    ])

    log_in
    get "/code/relay"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(repo.name)
    expect(response.body).to include("cmd")
    expect(response.body).to include("main.go")
    expect(response.body).to include("/code/relay/tree/cmd")
    expect(response.body).to include("/code/relay/blob/main.go")
  end

  it "renders a highlighted blob with line numbers" do
    create(:code_repository, slug: "relay", language: "Ruby")
    allow_any_instance_of(Code::RepoReaderService).to receive(:blob).and_return(
      {content: "def hello\n  puts \"hi\"\nend", language: "ruby", name: "hello.rb", size: 28}
    )

    log_in
    get "/code/relay/blob/hello.rb"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("3 lines")
    expect(response.body).to include("28 B")
    expect(response.body).to include('<div class="highlight">')
    expect(response.body).to include("<span") # rouge token spans
    expect(response.body).to include("hello")
  end

  it "404s for unknown repos and missing paths" do
    log_in
    get "/code/nope"
    expect(response).to have_http_status(:not_found)

    create(:code_repository, slug: "relay")
    allow_any_instance_of(Code::RepoReaderService).to receive(:tree)
      .and_raise(Code::RepoReaderService::NotFoundError, "not found")
    get "/code/relay/tree/missing/dir"
    expect(response).to have_http_status(:not_found)
  end
end
