# frozen_string_literal: true

# One livestream viewing session for a logged-in hackr. Opened when the
# StreamWatchChannel subscribes, credited +60s on each `periodically`
# heartbeat while the stream is live, and finalized on unsubscribe.
# A hackr accrues many sessions; their `accumulated_seconds` sum is the
# total watch time shown on the public profile.
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
class HackrWatchSession < ApplicationRecord
  # Open sessions whose heartbeat has gone quiet this long are presumed
  # dead (lost socket, no clean unsubscribe) and closed by the sweep job.
  STALE_AFTER = 5.minutes

  belongs_to :grid_hackr
  belongs_to :hackr_stream, optional: true

  scope :open_sessions, -> { where(disconnected_at: nil) }
  scope :stale, -> { open_sessions.where(last_heartbeat_at: ..STALE_AFTER.ago) }

  # Advance the heartbeat and credit elapsed watch time. Called from the
  # channel tick. update_columns skips callbacks/validation for speed.
  def heartbeat!(seconds)
    return if disconnected_at.present?

    update_columns(
      last_heartbeat_at: Time.current,
      accumulated_seconds: accumulated_seconds + seconds.to_i,
      updated_at: Time.current
    )
  end

  # Finalize on clean disconnect. Idempotent.
  def close!
    return if disconnected_at.present?

    update_columns(disconnected_at: Time.current, updated_at: Time.current)
  end

  # Close sessions abandoned without an unsubscribe, dating the close to
  # the last good heartbeat so idle time after disconnect isn't credited.
  def self.close_stale!
    stale.update_all("disconnected_at = last_heartbeat_at, updated_at = CURRENT_TIMESTAMP")
  end
end
