class CodeController < ApplicationController
  before_action :require_login
  before_action { request.format = :html } # a blob path's .json / .md / .css is not the response format
  before_action :set_repo, only: %i[show tree blob]

  HIGHLIGHT_MAX_SIZE = 262_144

  def index
    @repos = CodeRepository.browsable.to_a
    @last_sync = @repos.filter_map(&:last_synced_at).max
  end

  def show
    reader = Code::RepoReaderService.new(@repo)
    @entries = @repo.cloned? ? reader.tree : []
    @view_mode = :root
    readme = @entries.find { |e| e[:type] == "blob" && e[:name].casecmp?("README.md") }
    @readme = readme && reader.blob(readme[:path])
    render :browse
  rescue Code::RepoReaderService::BinaryFileError, Code::RepoReaderService::FileTooLargeError
    @readme = nil
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
    @repo = CodeRepository.browsable.find_by(slug: params[:repo].to_s.downcase)
    render :not_found, status: :not_found unless @repo
  end
end
