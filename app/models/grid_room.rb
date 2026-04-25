# == Schema Information
#
# Table name: grid_rooms
# Database name: primary
#
#  id                  :integer          not null, primary key
#  description         :text
#  locked              :boolean          default(FALSE), not null
#  min_clearance       :integer          default(0), not null
#  name                :string
#  room_type           :string
#  slug                :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  ambient_playlist_id :integer
#  grid_zone_id        :integer          not null
#  owner_id            :integer
#
# Indexes
#
#  index_grid_rooms_on_ambient_playlist_id  (ambient_playlist_id)
#  index_grid_rooms_on_grid_zone_id         (grid_zone_id)
#  index_grid_rooms_on_owner_id             (owner_id) UNIQUE
#  index_grid_rooms_on_slug                 (slug) UNIQUE
#
# Foreign Keys
#
#  ambient_playlist_id  (ambient_playlist_id => zone_playlists.id)
#  owner_id             (owner_id => grid_hackrs.id)
#
class GridRoom < ApplicationRecord
  include ProfanityFilterable

  has_paper_trail

  belongs_to :grid_zone
  belongs_to :ambient_playlist, class_name: "ZonePlaylist", optional: true
  belongs_to :owner, class_name: "GridHackr", optional: true

  has_many :exits_from, class_name: "GridExit", foreign_key: :from_room_id, dependent: :destroy
  has_many :exits_to, class_name: "GridExit", foreign_key: :to_room_id, dependent: :destroy
  has_many :grid_items, foreign_key: :room_id
  has_many :grid_mobs
  has_many :grid_hackrs, foreign_key: :current_room_id
  has_many :grid_breach_encounters, dependent: :destroy
  has_many :den_invites, class_name: "GridDenInvite", foreign_key: :den_id, dependent: :destroy

  validates :name, presence: true
  validates :name, length: {maximum: 80}, if: :den?
  validates :room_type, inclusion: {
    in: %w[hub faction_base govcorp special safe_zone transit shop danger_zone prism dream den hospital firmware_vendor repair_service containment impound sally_port sally_port_anteroom],
    allow_nil: true
  }
  validates :min_clearance, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :owner_id, uniqueness: {allow_nil: true}

  # Profanity filter: only for dens (user-controlled name + description).
  # Non-den rooms are admin-seeded — no filter needed.
  # Uses ProfanityFilterable#profane_content? to stay in sync with the concern.
  validate :filter_den_profanity

  def filter_den_profanity
    return unless den?
    %i[name description].each do |attr|
      value = public_send(attr)
      next if value.blank?
      if profane_content?(value)
        errors.add(attr, ProfanityFilterable.rejection_message)
      end
    end
  end

  # Delegate to zone for convenience
  delegate :faction, :color_scheme, to: :grid_zone

  def clearance_gated?
    min_clearance > 0
  end

  def breachable?
    grid_breach_encounters.any?
  end

  def den?
    room_type == "den"
  end

  def owned_den_of?(hackr)
    den? && owner_id == hackr.id
  end

  def den_floor_items
    grid_items.on_floor(self)
  end

  def den_floor_count
    den_floor_items.count
  end

  def placed_fixtures
    grid_items.placed_fixtures(self)
  end

  def den_fixture_capacity
    placed_fixtures.sum { |f| f.storage_capacity }
  end

  def den_stored_in_fixtures_count
    GridItem.where(container_id: placed_fixtures.select(:id)).count
  end
end
