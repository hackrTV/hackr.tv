require "rails_helper"

RSpec.describe CodeSyncJob, type: :job do
  it "calls GithubSyncService#sync_all" do
    service = instance_double(Code::GithubSyncService)
    allow(Code::GithubSyncService).to receive(:new).and_return(service)
    allow(service).to receive(:sync_all).and_return({synced: 3})

    described_class.perform_now

    expect(service).to have_received(:sync_all)
  end

  it "is enqueued in the default queue" do
    expect {
      described_class.perform_later
    }.to have_enqueued_job.on_queue("default")
  end
end
