module Api
  class CodeController < ApplicationController
    # GET /api/code
    def index
      repos = CodeRepository.browsable

      render json: repos.map { |repo| repo_json(repo) }
    end

    # GET /api/code/:repo
    def show
      repo = find_repo!
      reader = Code::RepoReaderService.new(repo)
      tree = repo.cloned? ? reader.tree : []

      render json: {repo: repo_json(repo), tree: tree}
    end

    # GET /api/code/:repo/tree/*path
    def tree
      repo = find_repo!
      reader = Code::RepoReaderService.new(repo)
      entries = reader.tree(params[:path])

      render json: {repo: repo_json(repo), path: params[:path], tree: entries}
    rescue Code::RepoReaderService::NotFoundError => e
      render json: {error: e.message}, status: :not_found
    end

    # GET /api/code/:repo/blob/*path
    def blob
      repo = find_repo!
      reader = Code::RepoReaderService.new(repo)
      result = reader.blob(params[:path])

      render json: {repo: repo_json(repo), **result}
    rescue Code::RepoReaderService::NotFoundError => e
      render json: {error: e.message}, status: :not_found
    rescue Code::RepoReaderService::BinaryFileError => e
      render json: {error: e.message}, status: :unprocessable_entity
    rescue Code::RepoReaderService::FileTooLargeError => e
      render json: {error: e.message}, status: :unprocessable_entity
    end

    private

    def find_repo!
      CodeRepository.browsable.find_by!(slug: params[:repo])
    rescue ActiveRecord::RecordNotFound
      render json: {error: "Repository not found"}, status: :not_found
    end

    def repo_json(repo)
      {
        name: repo.name,
        full_name: repo.full_name,
        slug: repo.slug,
        description: repo.description,
        language: repo.language,
        default_branch: repo.default_branch,
        homepage: repo.homepage,
        stargazers_count: repo.stargazers_count,
        size_kb: repo.size_kb,
        github_pushed_at: repo.github_pushed_at,
        last_synced_at: repo.last_synced_at
      }
    end
  end
end
