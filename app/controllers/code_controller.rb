# Server-rendered code browser (Hotwire migration Phase 1) — ports
# CodeIndexPage/CodeRepoPage/CodeTreeView/CodeBlobView. Login-gated like
# the SPA routes. Reuses Code::RepoReaderService; rouge replaces
# highlight.js. The JSON API stays for external consumers.
class CodeController < ApplicationController
  before_action :require_login
  before_action :set_repo, only: %i[show tree blob]

  LANGUAGE_COLORS = {
    "Ruby" => "#cc342d", "JavaScript" => "#f1e05a", "TypeScript" => "#3178c6",
    "Go" => "#00add8", "Python" => "#3572a5", "Rust" => "#dea584",
    "Shell" => "#89e051", "HTML" => "#e34c26", "CSS" => "#563d7c",
    "Lua" => "#000080", "C" => "#555555", "C++" => "#f34b7d",
    "Java" => "#b07219", "Swift" => "#ffac45", "Kotlin" => "#a97bff",
    "Elixir" => "#6e4a7e", "Dockerfile" => "#384d54"
  }.freeze

  def index
    @repos = CodeRepository.browsable
    @languages = @repos.filter_map(&:language).uniq.sort
  end

  def show
    reader = Code::RepoReaderService.new(@repo)
    @entries = @repo.cloned? ? reader.tree : []
    @view_mode = :root
    render :browse
  end

  def tree
    reader = Code::RepoReaderService.new(@repo)
    @entries = reader.tree(params[:path])
    @path = params[:path]
    @view_mode = :tree
    render :browse
  rescue Code::RepoReaderService::NotFoundError
    render :not_found, status: :not_found
  end

  def blob
    reader = Code::RepoReaderService.new(@repo)
    @blob = reader.blob(params[:path])
    @path = params[:path]
    @view_mode = :blob
    render :browse
  rescue Code::RepoReaderService::NotFoundError
    render :not_found, status: :not_found
  rescue Code::RepoReaderService::BinaryFileError, Code::RepoReaderService::FileTooLargeError => e
    @error_message = e.message
    render :error, status: :unprocessable_entity
  end

  private

  def set_repo
    @repo = CodeRepository.browsable.find_by(slug: params[:repo])
    render :not_found, status: :not_found unless @repo
  end
end
