# == Schema Information
#
# Table name: grid_achievements
# Database name: primary
#
#  id           :integer          not null, primary key
#  badge_icon   :string
#  category     :string           default("grid"), not null
#  cred_reward  :integer          default(0), not null
#  description  :text
#  hidden       :boolean          default(FALSE), not null
#  name         :string           not null
#  slug         :string           not null
#  trigger_data :json
#  trigger_type :string           not null
#  xp_reward    :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_grid_achievements_on_category      (category)
#  index_grid_achievements_on_slug          (slug) UNIQUE
#  index_grid_achievements_on_trigger_type  (trigger_type)
#
class GridAchievement < ApplicationRecord
  # Naming note: `uplink_packets_count` tracks what players see as
  # Uplink "packets" — an in-world aesthetic alias. The backing model
  # is `ChatMessage`; there is no separate Packet table. Similarly,
  # `wire_pulses_count` tracks WIRE "pulses" (model `Pulse`, which IS
  # its own table). Keep the in-world terminology in trigger names so
  # admin UI + YAML seed read consistently with user-facing copy.
  TRIGGER_TYPES = %w[
    rooms_visited
    room_visit
    items_collected
    take_item
    rarity_owned
    talk_npc
    use_item
    salvage_item
    salvage_count
    manual
    purchase_item
    track_plays_count
    pulse_vault_completed
    hackr_logs_read
    hackr_logs_read_all
    codex_entries_read
    codex_entries_read_all
    artist_bios_viewed_all
    release_indexes_viewed_all
    releases_viewed_all
    wire_pulses_count
    uplink_packets_count
    playlists_created
    vods_watched
    radio_stations_tuned
    radio_stations_tuned_all
    clearance_level
    missions_completed_count
    mission_completed
  ].freeze

  CATEGORIES = %w[grid music social meta progression].freeze

  # Trigger types that accumulate toward a threshold and can be resolved
  # retroactively by a login sweep. Event-only triggers (take_item,
  # room_visit, talk_npc, manual) are excluded — they fire on the action.
  CUMULATIVE_TRIGGERS = %w[
    rooms_visited items_collected salvage_count
    track_plays_count pulse_vault_completed
    hackr_logs_read hackr_logs_read_all
    codex_entries_read codex_entries_read_all
    artist_bios_viewed_all release_indexes_viewed_all releases_viewed_all
    wire_pulses_count uplink_packets_count playlists_created
    vods_watched radio_stations_tuned radio_stations_tuned_all
    clearance_level
    missions_completed_count
  ].freeze

  has_many :grid_hackr_achievements, dependent: :destroy
  has_many :grid_hackrs, through: :grid_hackr_achievements

  validates :slug, presence: true, uniqueness: true
  validates :name, presence: true
  validates :trigger_type, presence: true, inclusion: {in: TRIGGER_TYPES}
  validates :category, presence: true, inclusion: {in: CATEGORIES}
  validates :xp_reward, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :cred_reward, numericality: {only_integer: true, greater_than_or_equal_to: 0}

  scope :by_trigger, ->(type) { where(trigger_type: type) }
  scope :by_category, ->(cat) { where(category: cat) }
  scope :visible, -> { where(hidden: false) }
end
