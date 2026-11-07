require "rails_helper"

# The /code console screens (code-browser-console, 2026-11-06). Login-gated;
# RepoReaderService is stubbed (no cloned repos on disk in test).
RSpec.describe "Code pages", type: :request do
  let(:hackr) { create(:grid_hackr, password: "hackthegrid") }

  def log_in
    post "/api/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  def stub_tree(entries)
    allow_any_instance_of(CodeRepository).to receive(:cloned?).and_return(true)
    allow_any_instance_of(Code::RepoReaderService).to receive(:tree).and_return(entries)
  end

  def stub_blob(blob)
    allow_any_instance_of(Code::RepoReaderService).to receive(:blob).and_return(blob)
  end

  let(:hello_blob) { {content: "def hello\n  puts \"hi\"\nend", language: "ruby", name: "hello.rb", path: "hello.rb", size: 28, sha: "a" * 40} }

  it "redirects anonymous visitors to the grid login" do
    get "/code"
    expect(response).to redirect_to("/grid/login")
  end

  describe "the index" do
    it "is a console screen with a FILTER row and a numbered repo ledger" do
      create(:code_repository, name: "relay", slug: "relay", language: "Go", description: "Chat aggregator", stargazers_count: 0, size_kb: 51, last_synced_at: Time.zone.local(2026, 11, 6, 14, 10))
      create(:code_repository, name: "synthia", slug: "synthia", language: "Ruby", stargazers_count: 7, last_synced_at: Time.zone.local(2026, 11, 5, 4, 0))
      create(:code_repository, :hidden, name: "secret-repo", slug: "secret-repo")

      log_in
      get "/code"

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('class="console console--code" data-controller="terminal ledger-filter" data-boot="done"')
      expect(body).not_to include("chrome-ascii")
      expect(body).not_to include('style="')
      expect(body).to include("CODE</h1>")
      expect(body).to include("[&lt;] HOME")
      expect(body).to include("2 repositories <span class=\"console-dim\">· Go · Ruby</span>")
      expect(body).to include("2126-11-06 14:10")
      expect(body).to include('data-ledger-filter-target="input"')
      expect(body).to include('data-ledger-filter-target="count">2 / 2<')
      expect(body).to include('data-search="relay chat aggregator go"')
      expect(body).to include('data-command="01" href="/code/synthia"')
      expect(body).to include('data-command="02" href="/code/relay"')
      expect(body).to include("RUBY · ★ 7 · pushed")
      expect(body).to include("GO · pushed")
      expect(body).to include("51.0 KB")
      expect(body).not_to include("secret-repo")
      expect(body).to include("(01 02)")
      expect(body).to include("(home)")
      expect(body).to include('data-command="home" href="/"')
      expect(body).not_to include('data-command="code"')
    end

    it "says so when nothing is on record" do
      log_in
      get "/code"
      expect(response.body).to include("NO REPOSITORIES ON RECORD")
      expect(response.body).to include("NONE ON RECORD")
    end
  end

  describe "a repo root" do
    before { create(:code_repository, slug: "relay", name: "relay", full_name: "hackrTV/relay", default_branch: "main", description: "Chat aggregator") }

    it "renders the numbered tree with sizes, no UP, and the root README below it" do
      stub_tree([
        {name: "cmd", path: "cmd", type: "tree", sha: "b" * 40, size: nil},
        {name: "main.go", path: "main.go", type: "blob", sha: "c" * 40, size: 2048},
        {name: "README.md", path: "README.md", type: "blob", sha: "d" * 40, size: 30},
        {name: "vendor/x", path: "vendor/x", type: "commit", sha: "e" * 40, size: nil}
      ])
      stub_blob({content: "# Relay\n\nHello *there*", language: "markdown", name: "README.md", path: "README.md", size: 30, sha: "d" * 40})

      log_in
      get "/code/relay"

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include("relay</h1>")
      expect(body).to include("main · ROOT")
      expect(body).not_to include("[^] UP")
      expect(body).not_to include("[..]")
      expect(body).to include('href="https://github.com/hackrTV/relay"')
      expect(body).to include("· 4 entries")
      expect(body).to include('data-command="01" href="/code/relay/tree/cmd">cmd/<')
      expect(body).to include('data-command="02" href="/code/relay/blob/main.go">main.go<')
      expect(body).to include('<span class="cb-size">2.0 KB</span>')
      expect(body).to include('data-command="03" href="/code/relay/blob/README.md"')
      expect(body).to include("vendor/x @ eeeeeee")
      expect(body).to include("SUBMODULE")
      expect(body).not_to include('data-command="04"')
      expect(body).to include("// README //")
      expect(body).to include("<em>there</em>")
      expect(body).to include("(01 02 03 04)")
      expect(body).to include("(code home)")
    end

    it "skips the README section when the root has none" do
      stub_tree([{name: "main.go", path: "main.go", type: "blob", sha: "c" * 40, size: 10}])

      log_in
      get "/code/relay"

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("// README //")
    end

    it "points the README's relative links at the repo's code screens" do
      stub_tree([{name: "README.md", path: "README.md", type: "blob", sha: "d" * 40, size: 30}])
      stub_blob({content: "[guide](docs/GUIDE.md) [lic](UNLICENSE) [notes](docs/My%20Notes.md) [docs](docs/) [top](#top) [gh](https://github.com/hackrTV)",
                 language: "markdown", name: "README.md", path: "README.md", size: 30, sha: "d" * 40})

      log_in
      get "/code/relay"

      body = response.body
      expect(body).to include('href="/code/relay/blob/docs/GUIDE.md"')
      expect(body).to include('href="/code/relay/blob/UNLICENSE"')
      expect(body).to include('href="/code/relay/blob/docs/My%20Notes.md"')
      expect(body).to include('href="/code/relay/tree/docs"')
      expect(body).to include('href="#top"')
      expect(body).to include('href="https://github.com/hackrTV"')
    end

    it "still renders the tree when the README cannot be shown" do
      stub_tree([{name: "README.md", path: "README.md", type: "blob", sha: "d" * 40, size: 30}])
      allow_any_instance_of(Code::RepoReaderService).to receive(:blob)
        .and_raise(Code::RepoReaderService::BinaryFileError, "Binary file detected")

      log_in
      get "/code/relay"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-command="01" href="/code/relay/blob/README.md"')
      expect(response.body).not_to include("// README //")
    end

    it "finds the repo from a cased slug" do
      stub_tree([])

      log_in
      get "/code/Relay"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("relay</h1>")
    end
  end

  describe "a subtree" do
    before { create(:code_repository, slug: "relay", default_branch: "main") }

    it "offers UP and [..] as the .. command and links the PATH segments" do
      stub_tree([])

      log_in
      get "/code/relay/tree/cmd/sub"

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include("main · cmd/sub")
      expect(body).to include('data-command=".." href="/code/relay/tree/cmd">[^] UP')
      expect(body).to include('data-command=".." href="/code/relay/tree/cmd">../<')
      expect(body).to include('<a class="console-link" href="/code/relay/tree/cmd">cmd</a>')
      expect(body).to include("<span>sub</span>")
      expect(body).to include("EMPTY DIRECTORY")
      expect(body).to include("(.. code home)")
    end

    it "sends a first-level directory UP to the repo root" do
      stub_tree([])

      log_in
      get "/code/relay/tree/cmd"

      expect(response.body).to include('data-command=".." href="/code/relay">[^] UP')
    end
  end

  describe "a blob" do
    before { create(:code_repository, slug: "relay", default_branch: "main") }

    it "renders the SIZE row, a gutter of line anchors and one div per highlighted line" do
      stub_blob(hello_blob)

      log_in
      get "/code/relay/blob/hello.rb"

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include('data-controller="terminal" data-boot="done" data-terminal-autofocus-value="false"')
      expect(body).to include("main · hello.rb")
      expect(body).to include('data-command=".." href="/code/relay">[^] UP')
      expect(body).to include("FILE</span>")
      expect(body).to include("28 B <span class=\"console-dim\">· 3 lines · RUBY</span>")
      expect(body).to include("// SOURCE //")
      expect(body).to include('<a href="#L1">1</a>')
      expect(body).to include('<a href="#L3">3</a>')
      expect(body).not_to include('<a href="#L4">')
      expect(body).to include('<div class="highlight">')
      expect(body).to include('<div id="L1" class="cb-line"><span class="k">def</span>')
      expect(body).to include('<div id="L3" class="cb-line"><span class="k">end</span></div>')
      expect(body).not_to include("NOT HIGHLIGHTED")
    end

    it "keeps uppercase and dotted paths: README.md is not downcased or format-negotiated" do
      stub_blob({content: "# Relay\n", language: "markdown", name: "README.md", path: "README.md", size: 8, sha: "d" * 40})

      log_in
      get "/code/relay/blob/README.md"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("// MARKDOWN //")
      expect(response.body).to include("<h1>Relay</h1>")
      expect(response.body).not_to include("cb-gutter")

      stub_blob({content: "{}\n", language: "json", name: "package.json", path: "package.json", size: 3, sha: "f" * 40})
      get "/code/relay/blob/package.json"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("· 1 line · JSON")
    end

    it "resolves a nested markdown file's relative links from its directory" do
      stub_blob({content: "[back](../README.md) [sib](OTHER.md)", language: "markdown", name: "GUIDE.md", path: "docs/GUIDE.md", size: CodeController::HIGHLIGHT_MAX_SIZE + 1, sha: "e" * 40})

      log_in
      get "/code/relay/blob/docs/GUIDE.md"

      expect(response.body).to include('href="/code/relay/blob/README.md"')
      expect(response.body).to include('href="/code/relay/blob/docs/OTHER.md"')
      expect(response.body).not_to include("NOT HIGHLIGHTED")
    end

    it "renders files past the highlight cap as plain lines" do
      stub_blob(hello_blob.merge(size: CodeController::HIGHLIGHT_MAX_SIZE + 1))

      log_in
      get "/code/relay/blob/hello.rb"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("NOT HIGHLIGHTED")
      expect(response.body).to include('<div id="L2" class="cb-line">  puts "hi"</div>')
      expect(response.body).not_to include('<span class="k">')
    end

    it "caches the highlighted fragment by content sha" do
      memory_store = ActiveSupport::Cache::MemoryStore.new
      allow(Rails).to receive(:cache).and_return(memory_store)
      allow(Rouge::Lexer).to receive(:find).and_call_original
      stub_blob(hello_blob)

      log_in
      get "/code/relay/blob/hello.rb"
      get "/code/relay/blob/hello.rb"
      expect(Rouge::Lexer).to have_received(:find).once
      expect(response.body).to include('<div id="L1" class="cb-line"><span class="k">def</span>')

      stub_blob(hello_blob.merge(sha: "b" * 40))
      get "/code/relay/blob/hello.rb"
      expect(Rouge::Lexer).to have_received(:find).twice
    end
  end

  describe "misses" do
    it "404s unknown repos and missing paths as console screens" do
      log_in
      get "/code/nope"
      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("// SIGNAL LOST //")
      expect(response.body).to include('data-command="code" href="/code"')

      create(:code_repository, slug: "relay", name: "relay")
      allow_any_instance_of(Code::RepoReaderService).to receive(:tree)
        .and_raise(Code::RepoReaderService::NotFoundError, "not found")
      get "/code/relay/tree/missing/dir"
      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("relay</h1>")
    end

    it "422s a binary file with the way back up" do
      create(:code_repository, slug: "relay", name: "relay", default_branch: "main")
      allow_any_instance_of(Code::RepoReaderService).to receive(:blob)
        .and_raise(Code::RepoReaderService::BinaryFileError, "Binary file type: .png")

      log_in
      get "/code/relay/blob/img/logo.png"

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("// CANNOT DISPLAY //")
      expect(response.body).to include("Binary file type: .png")
      expect(response.body).to include('data-command=".." href="/code/relay/tree/img">[^] UP')
    end
  end

  it "ships rouge.css in the tracked asset set of every page, not just the browser" do
    log_in
    get "/code"
    expect(response.body).to match(%r{<link rel="stylesheet" href="/assets/rouge-[^"]+\.css" data-turbo-track="reload"})
    get "/schedule"
    expect(response.body).to match(%r{<link rel="stylesheet" href="/assets/rouge-[^"]+\.css" data-turbo-track="reload"})
  end
end
