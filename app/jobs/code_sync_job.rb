class CodeSyncJob < ApplicationJob
  queue_as :default

  def perform
    Code::GithubSyncService.new.sync_all
  end
end
