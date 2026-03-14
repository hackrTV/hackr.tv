module Code
  class GithubSyncService
    ORG_NAME = "hackrTV"

    # Only these repos will be synced from the hackrTV org
    REPO_ALLOWLIST = %w[
      hackr.tv
      relay
      synthia
    ].freeze

    def initialize
      @client = Octokit::Client.new(
        access_token: github_token,
        auto_paginate: true
      )
    end

    def sync_all
      synced_github_ids = []

      REPO_ALLOWLIST.each do |repo_name|
        repo = fetch_repo(repo_name)
        next unless repo

        record = sync_repo_metadata(repo)
        sync_repo_files(record)
        synced_github_ids << repo.id
      rescue => e
        Rails.logger.error("[CodeSync] Error syncing #{ORG_NAME}/#{repo_name}: #{e.message}")
        record&.update(sync_error: e.message, sync_status: "error")
      end

      # Mark repos not in the allowlist as not visible
      allowlist_slugs = REPO_ALLOWLIST.map { |name| name.downcase.gsub(/[^a-z0-9\s-]/, "").gsub(/\s+/, "-").squeeze("-") }
      CodeRepository.where.not(slug: allowlist_slugs).update_all(visible: false)

      {synced: synced_github_ids.size}
    end

    private

    def github_token
      ENV["HACKRTV_GITHUB_TOKEN"] || Rails.application.credentials.dig(:github, :token)
    end

    def fetch_repo(name)
      @client.repo("#{ORG_NAME}/#{name}")
    rescue Octokit::Unauthorized => e
      Rails.logger.error("[CodeSync] GitHub token expired: #{e.message}")
      CodeMailer.token_expired(e.message).deliver_later
      nil
    rescue Octokit::NotFound
      Rails.logger.warn("[CodeSync] Repo not found: #{ORG_NAME}/#{name}")
      nil
    end

    def sync_repo_metadata(repo)
      record = CodeRepository.find_or_initialize_by(github_id: repo.id)
      record.assign_attributes(
        name: repo.name,
        full_name: repo.full_name,
        slug: repo.name.downcase.gsub(/[^a-z0-9\s-]/, "").gsub(/\s+/, "-").squeeze("-"),
        description: repo.description,
        language: repo.language,
        default_branch: repo.default_branch,
        homepage: repo.homepage,
        stargazers_count: repo.stargazers_count,
        size_kb: repo.size,
        github_pushed_at: repo.pushed_at,
        visible: true
      )
      record.save!
      record
    end

    def sync_repo_files(record)
      repo_path = record.bare_repo_path
      FileUtils.mkdir_p(repo_path.dirname)

      if record.cloned?
        # Fetch updates
        _output, status = Open3.capture2("git", "-C", repo_path.to_s, "fetch", "--prune")
        unless status.success?
          record.update(sync_error: "git fetch failed", sync_status: "error")
          return
        end
      else
        # Clone bare
        _output, status = Open3.capture2("git", "clone", "--bare",
          "https://github.com/#{record.full_name}.git", repo_path.to_s)
        unless status.success?
          record.update(sync_error: "git clone failed", sync_status: "error")
          return
        end
      end

      record.update(last_synced_at: Time.current, sync_status: "synced", sync_error: nil)
    end
  end
end
