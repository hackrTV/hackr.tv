require "rails_helper"

# The roster debounce against a real cache store: the test environment
# runs Rails.cache as a null_store, where write(unless_exist:) always
# reports a win and every presence change would enqueue its own job.
RSpec.describe Uplink::MembersBroadcaster do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  let(:channel) { create(:chat_channel, slug: "ambient") }

  before do
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  after { Rails.cache = @original_cache }

  describe ".schedule" do
    it "enqueues one trailing job per window: the first change claims it, later ones ride along" do
      expect { 3.times { described_class.schedule(channel.id) } }
        .to have_enqueued_job(Uplink::MembersBroadcastJob).with(channel.id).once
    end

    it "claims per channel" do
      other = create(:chat_channel, slug: "trace")

      expect {
        described_class.schedule(channel.id)
        described_class.schedule(other.id)
      }.to have_enqueued_job(Uplink::MembersBroadcastJob).twice
    end

    it "schedules again once the claim is released" do
      described_class.schedule(channel.id)
      described_class.release(channel.id)

      expect { described_class.schedule(channel.id) }
        .to have_enqueued_job(Uplink::MembersBroadcastJob).with(channel.id).once
    end

    it "lets a claim whose job never ran expire after CLAIM_TTL" do
      described_class.schedule(channel.id)

      travel(described_class::CLAIM_TTL + 1.second) do
        expect { described_class.schedule(channel.id) }
          .to have_enqueued_job(Uplink::MembersBroadcastJob).with(channel.id).once
      end
    end
  end

  describe "the trailing job" do
    it "releases the claim before rendering, so a change that lands mid-render schedules the next one" do
      described_class.schedule(channel.id)
      allow(described_class).to receive(:broadcast) { described_class.schedule(channel.id) } # a presence change mid-render

      expect { Uplink::MembersBroadcastJob.perform_now(channel.id) }
        .to have_enqueued_job(Uplink::MembersBroadcastJob).with(channel.id).once
      expect(described_class).to have_received(:broadcast).with(channel)
    end
  end
end
