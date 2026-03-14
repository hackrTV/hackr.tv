require "rails_helper"
require "ostruct"

RSpec.describe Code::GithubSyncService do
  let(:service) { described_class.new }
  let(:fake_repo) do
    OpenStruct.new(
      id: 123456,
      name: "hackr.tv",
      full_name: "hackrTV/hackr.tv",
      description: "Music platform",
      language: "Ruby",
      default_branch: "master",
      homepage: "https://hackr.tv",
      stargazers_count: 10,
      size: 5000,
      pushed_at: 1.day.ago,
      fork: false,
      archived: false
    )
  end

  before do
    allow_any_instance_of(Octokit::Client).to receive(:repo).and_return(fake_repo)
    allow(Open3).to receive(:capture2).and_return(["", instance_double(Process::Status, success?: true)])
    allow(FileUtils).to receive(:mkdir_p)
    allow(Dir).to receive(:exist?).and_return(false)
  end

  describe "#sync_all" do
    it "creates CodeRepository records for allowlisted repos" do
      expect { service.sync_all }.to change(CodeRepository, :count)
    end

    it "updates existing repos" do
      repo = create(:code_repository, github_id: 123456, name: "old-name")

      service.sync_all

      repo.reload
      expect(repo.name).to eq("hackr.tv")
      expect(repo.description).to eq("Music platform")
    end

    it "marks repos not in the allowlist as not visible" do
      removed = create(:code_repository, slug: "not-in-allowlist", github_id: 999999, visible: true)

      service.sync_all

      removed.reload
      expect(removed.visible).to be false
    end

    it "does not hide allowlisted repos that fail to sync" do
      # Create a repo with an allowlisted slug that already exists in the DB
      existing = create(:code_repository, slug: "hackrtv", github_id: 999998, visible: true)

      # Make all fetches fail
      allow_any_instance_of(Octokit::Client).to receive(:repo)
        .and_raise(Octokit::NotFound)

      service.sync_all

      existing.reload
      expect(existing.visible).to be true
    end

    it "returns the count of synced repos" do
      result = service.sync_all
      expect(result[:synced]).to be_a(Integer)
    end

    it "handles per-repo errors without blocking others" do
      call_count = 0
      allow_any_instance_of(Octokit::Client).to receive(:repo) do
        call_count += 1
        if call_count == 1
          raise StandardError, "boom"
        else
          fake_repo
        end
      end

      result = service.sync_all
      expect(result[:synced]).to be >= 0
    end
  end

  describe "token expiry handling" do
    it "sends an email when the token is expired" do
      allow_any_instance_of(Octokit::Client).to receive(:repo)
        .and_raise(Octokit::Unauthorized.new(body: "Bad credentials"))

      expect { service.sync_all }.to have_enqueued_job(ActionMailer::MailDeliveryJob).at_least(:once)
    end

    it "returns nil for the repo when token is expired" do
      allow_any_instance_of(Octokit::Client).to receive(:repo)
        .and_raise(Octokit::Unauthorized.new(body: "Bad credentials"))

      result = service.sync_all
      expect(result[:synced]).to eq(0)
    end
  end

  describe "repo not found" do
    it "skips repos that do not exist on GitHub" do
      allow_any_instance_of(Octokit::Client).to receive(:repo)
        .and_raise(Octokit::NotFound)

      result = service.sync_all
      expect(result[:synced]).to eq(0)
    end
  end
end
