# == Schema Information
#
# Table name: grid_uplink_presences
# Database name: primary
#
#  id              :integer          not null, primary key
#  last_seen_at    :datetime         not null
#  chat_channel_id :integer          not null
#  grid_hackr_id   :integer          not null
#
# Indexes
#
#  index_grid_uplink_presences_on_last_seen_at  (last_seen_at)
#  index_grid_uplink_presences_unique           (grid_hackr_id,chat_channel_id) UNIQUE
#
# One row per hackr per Uplink channel while their LiveChatChannel
# subscription is alive (touched on subscribe + every 60s, removed on
# unsubscribe; PRESENCE_TTL bounds unclean disconnects). Read by the
# mining economy and, since 2026-10, rendered anonymized as the /uplink
# shell's operatives roster — hence the commit callbacks that schedule a
# roster broadcast when a row appears, goes, or comes back from stale.
class GridUplinkPresence < ApplicationRecord
  belongs_to :grid_hackr
  belongs_to :chat_channel

  # One after_commit per method name: Rails dedupes commit callbacks by
  # method, so registering :schedule_roster_broadcast for create, destroy
  # and update separately would keep only the last one.
  after_commit :schedule_roster_broadcast, on: [:create, :destroy]
  after_update_commit :schedule_roster_broadcast_on_return

  scope :valid, -> { where("last_seen_at > ?", Grid::EconomyConfig::PRESENCE_TTL.ago) }
  scope :in_channel, ->(channel) { where(chat_channel: channel) }
  scope :for_hackr, ->(hackr) { where(grid_hackr: hackr) }

  # The unique index settles two first touches racing for one row (the
  # same hackr subscribing from two processes at once — LiveChatChannel's
  # subscription refcount is in-process only): the loser retries once
  # and updates the winner's row instead (no second broadcast — the
  # winner's create scheduled it).
  def self.touch!(hackr, channel, attempt: 0)
    presence = find_or_initialize_by(grid_hackr: hackr, chat_channel: channel)
    presence.last_seen_at = Time.current
    presence.save!
    presence
  rescue ActiveRecord::RecordNotUnique
    raise if attempt.positive?

    touch!(hackr, channel, attempt: 1)
  end

  # destroy (not delete) so the roster hears about it.
  def self.remove!(hackr, channel)
    where(grid_hackr: hackr, chat_channel: channel).destroy_all.size
  end

  # delete_all skips callbacks (fine for the economy, the rows were
  # already outside `valid`), so refresh the rosters that still show the
  # ghosts — one broadcast per affected channel.
  def self.cleanup_stale!
    stale = where("last_seen_at < ?", Grid::EconomyConfig::PRESENCE_TTL.ago)
    channel_ids = stale.distinct.pluck(:chat_channel_id)
    stale.delete_all.tap { channel_ids.each { |id| Uplink::MembersBroadcaster.schedule(id) } }
  end

  private

  # The 60s periodic touch is a no-op for the roster unless the row had
  # already aged out of `valid` (the hackr looked gone, now is back).
  def returned_from_stale?
    before = last_seen_at_before_last_save
    before.present? && before <= Grid::EconomyConfig::PRESENCE_TTL.ago
  end

  def schedule_roster_broadcast
    Uplink::MembersBroadcaster.schedule(chat_channel_id)
  end

  def schedule_roster_broadcast_on_return
    schedule_roster_broadcast if returned_from_stale?
  end
end
