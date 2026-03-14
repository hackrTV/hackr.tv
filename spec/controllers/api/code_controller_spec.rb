require "rails_helper"

RSpec.describe Api::CodeController, type: :controller do
  describe "GET #index" do
    it "returns browsable repositories" do
      repo = create(:code_repository)
      create(:code_repository, :hidden)
      create(:code_repository, :unsynced)

      get :index, format: :json

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json.length).to eq(1)
      expect(json.first["slug"]).to eq(repo.slug)
    end

    it "returns repos ordered by stargazers_count desc" do
      repo_low = create(:code_repository, stargazers_count: 1)
      repo_high = create(:code_repository, stargazers_count: 100)

      get :index, format: :json

      json = JSON.parse(response.body)
      expect(json.first["slug"]).to eq(repo_high.slug)
      expect(json.last["slug"]).to eq(repo_low.slug)
    end

    it "returns expected fields for each repo" do
      create(:code_repository, name: "test-repo", language: "Ruby", stargazers_count: 42)

      get :index, format: :json

      json = JSON.parse(response.body)
      repo = json.first
      expect(repo).to include("name", "full_name", "slug", "description", "language",
        "default_branch", "stargazers_count", "github_pushed_at")
    end
  end

  describe "GET #show" do
    it "returns repo detail with tree" do
      repo = create(:code_repository, slug: "my-repo")
      allow(Dir).to receive(:exist?).and_call_original
      allow(Dir).to receive(:exist?).with(repo.bare_repo_path).and_return(false)

      get :show, params: {repo: "my-repo"}, format: :json

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["repo"]["slug"]).to eq("my-repo")
      expect(json["tree"]).to eq([])
    end

    it "returns 404 for nonexistent repo" do
      get :show, params: {repo: "nonexistent"}, format: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET #tree" do
    let!(:repo) { create(:code_repository, slug: "my-repo") }

    it "returns directory listing" do
      tree_entries = [{name: "README.md", path: "README.md", type: "blob"}]
      reader = instance_double(Code::RepoReaderService)
      allow(Code::RepoReaderService).to receive(:new).and_return(reader)
      allow(reader).to receive(:tree).with("src").and_return(tree_entries)

      get :tree, params: {repo: "my-repo", path: "src"}, format: :json

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["tree"].length).to eq(1)
      expect(json["path"]).to eq("src")
    end

    it "returns 404 for nonexistent path" do
      reader = instance_double(Code::RepoReaderService)
      allow(Code::RepoReaderService).to receive(:new).and_return(reader)
      allow(reader).to receive(:tree).and_raise(Code::RepoReaderService::NotFoundError, "not found")

      get :tree, params: {repo: "my-repo", path: "nonexistent"}, format: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET #blob" do
    let!(:repo) { create(:code_repository, slug: "my-repo") }

    it "returns file content" do
      blob_data = {path: "app.rb", name: "app.rb", content: "puts 'hello'", size: 12, language: "ruby"}
      reader = instance_double(Code::RepoReaderService)
      allow(Code::RepoReaderService).to receive(:new).and_return(reader)
      allow(reader).to receive(:blob).with("app.rb").and_return(blob_data)

      get :blob, params: {repo: "my-repo", path: "app.rb"}, format: :json

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["content"]).to eq("puts 'hello'")
      expect(json["language"]).to eq("ruby")
    end

    it "returns 404 for nonexistent file" do
      reader = instance_double(Code::RepoReaderService)
      allow(Code::RepoReaderService).to receive(:new).and_return(reader)
      allow(reader).to receive(:blob).and_raise(Code::RepoReaderService::NotFoundError, "not found")

      get :blob, params: {repo: "my-repo", path: "missing.rb"}, format: :json

      expect(response).to have_http_status(:not_found)
    end

    it "returns 422 for binary files" do
      reader = instance_double(Code::RepoReaderService)
      allow(Code::RepoReaderService).to receive(:new).and_return(reader)
      allow(reader).to receive(:blob).and_raise(Code::RepoReaderService::BinaryFileError, "binary")

      get :blob, params: {repo: "my-repo", path: "image.png"}, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 422 for oversized files" do
      reader = instance_double(Code::RepoReaderService)
      allow(Code::RepoReaderService).to receive(:new).and_return(reader)
      allow(reader).to receive(:blob).and_raise(Code::RepoReaderService::FileTooLargeError, "too large")

      get :blob, params: {repo: "my-repo", path: "huge.rb"}, format: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
