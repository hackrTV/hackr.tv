require "rails_helper"

RSpec.describe StreamWatchChannel, type: :channel do
  let(:hackr) { create(:grid_hackr) }

  it "rejects anonymous connections" do
    stub_connection current_hackr: nil
    subscribe
    expect(subscription).to be_rejected
  end

  it "rejects when no stream is live" do
    stub_connection current_hackr: hackr
    subscribe
    expect(subscription).to be_rejected
  end

  context "with a live stream" do
    before { create(:hackr_stream, :live) }

    it "opens a watch session on subscribe" do
      stub_connection current_hackr: hackr
      expect { subscribe }.to change { hackr.watch_sessions.open_sessions.count }.by(1)
      expect(subscription).to be_confirmed
    end

    it "closes the session on unsubscribe" do
      stub_connection current_hackr: hackr
      subscribe
      session = hackr.watch_sessions.last
      unsubscribe
      expect(session.reload.disconnected_at).to be_present
    end

    it "rejects a second concurrent subscription for the same hackr" do
      stub_connection current_hackr: hackr
      subscribe
      expect(subscription).to be_confirmed

      stub_connection current_hackr: hackr
      subscribe
      expect(subscription).to be_rejected
    end

    it "credits watch time on a tick while live" do
      stub_connection current_hackr: hackr
      subscribe
      session = hackr.watch_sessions.last
      expect { subscription.send(:credit_tick) }
        .to change { session.reload.accumulated_seconds }.by(StreamWatchChannel::TICK_SECONDS)
    end

    it "stops crediting once the stream ends" do
      stub_connection current_hackr: hackr
      subscribe
      HackrStream.current_live.update!(is_live: false)
      session = hackr.watch_sessions.last
      expect { subscription.send(:credit_tick) }
        .not_to(change { session.reload.accumulated_seconds })
    end
  end
end
