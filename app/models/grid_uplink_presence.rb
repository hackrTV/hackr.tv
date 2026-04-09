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
class GridUplinkPresence < ApplicationRecord
  belongs_to :grid_hackr
  belongs_to :chat_channel

  scope :valid, -> { where("last_seen_at > ?", Grid::EconomyConfig::PRESENCE_TTL.ago) }
  scope :in_channel, ->(channel) { where(chat_channel: channel) }
  scope :for_hackr, ->(hackr) { where(grid_hackr: hackr) }

  def self.touch!(hackr, channel)
    presence = find_or_initialize_by(grid_hackr: hackr, chat_channel: channel)
    presence.last_seen_at = Time.current
    presence.save!
    presence
  end

  def self.remove!(hackr, channel)
    where(grid_hackr: hackr, chat_channel: channel).delete_all
  end

  def self.cleanup_stale!
    where("last_seen_at < ?", Grid::EconomyConfig::PRESENCE_TTL.ago).delete_all
  end
end
