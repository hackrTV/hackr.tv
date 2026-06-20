# == Schema Information
#
# Table name: hackr_watch_sessions
# Database name: primary
#
#  id                  :integer          not null, primary key
#  accumulated_seconds :integer          default(0), not null
#  connected_at        :datetime         not null
#  disconnected_at     :datetime
#  last_heartbeat_at   :datetime         not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  grid_hackr_id       :integer          not null
#  hackr_stream_id     :integer
#
# Indexes
#
#  idx_on_grid_hackr_id_disconnected_at_e34a883d93  (grid_hackr_id,disconnected_at)
#  index_hackr_watch_sessions_on_grid_hackr_id      (grid_hackr_id)
#  index_hackr_watch_sessions_on_hackr_stream_id    (hackr_stream_id)
#  index_hackr_watch_sessions_on_last_heartbeat_at  (last_heartbeat_at)
#  index_hackr_watch_sessions_one_open_per_hackr    (grid_hackr_id) UNIQUE WHERE disconnected_at IS NULL
#
# Foreign Keys
#
#  grid_hackr_id    (grid_hackr_id => grid_hackrs.id)
#  hackr_stream_id  (hackr_stream_id => hackr_streams.id)
#
require "rails_helper"

RSpec.describe HackrWatchSession, type: :model do
  let(:hackr) { create(:grid_hackr) }

  def open_session(owner: hackr, heartbeat_at: Time.current)
    HackrWatchSession.create!(
      grid_hackr: owner,
      connected_at: heartbeat_at,
      last_heartbeat_at: heartbeat_at,
      accumulated_seconds: 0
    )
  end

  describe "#heartbeat!" do
    it "credits seconds and advances the heartbeat" do
      session = open_session(heartbeat_at: 2.minutes.ago)
      session.heartbeat!(60)
      session.reload
      expect(session.accumulated_seconds).to eq(60)
      expect(session.last_heartbeat_at).to be_within(2.seconds).of(Time.current)
    end

    it "does not credit a closed session" do
      session = open_session
      session.close!
      expect { session.heartbeat!(60) }.not_to(change { session.reload.accumulated_seconds })
    end
  end

  describe "#close!" do
    it "stamps disconnected_at and is idempotent" do
      session = open_session
      session.close!
      first = session.reload.disconnected_at
      expect(first).to be_present
      session.close!
      expect(session.reload.disconnected_at).to eq(first)
    end
  end

  describe ".close_stale!" do
    it "closes stale open sessions dated to their last heartbeat, leaving fresh ones open" do
      stale = open_session(heartbeat_at: 10.minutes.ago)
      fresh = open_session(owner: create(:grid_hackr), heartbeat_at: 1.minute.ago)

      HackrWatchSession.close_stale!

      expect(stale.reload.disconnected_at).to be_within(2.seconds).of(stale.last_heartbeat_at)
      expect(fresh.reload.disconnected_at).to be_nil
    end
  end

  describe "one open session per hackr" do
    it "rejects a second open session for the same hackr" do
      open_session
      expect { open_session }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows a new open session after the prior one closes" do
      open_session.close!
      expect { open_session }.not_to raise_error
    end
  end

  describe "stream deletion" do
    it "nullifies the FK instead of blocking, preserving the watch total" do
      stream = create(:hackr_stream, :live)
      session = HackrWatchSession.create!(
        grid_hackr: hackr, hackr_stream: stream,
        connected_at: Time.current, last_heartbeat_at: Time.current, accumulated_seconds: 120
      )

      expect { stream.destroy! }.not_to raise_error
      expect(session.reload.hackr_stream_id).to be_nil
      expect(session.accumulated_seconds).to eq(120)
    end
  end
end
