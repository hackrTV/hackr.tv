# == Schema Information
#
# Table name: grid_achievements
# Database name: primary
#
#  id           :integer          not null, primary key
#  badge_icon   :string
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
#  index_grid_achievements_on_slug          (slug) UNIQUE
#  index_grid_achievements_on_trigger_type  (trigger_type)
#
class GridAchievement < ApplicationRecord
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
  ].freeze

  has_many :grid_hackr_achievements, dependent: :destroy
  has_many :grid_hackrs, through: :grid_hackr_achievements

  validates :slug, presence: true, uniqueness: true
  validates :name, presence: true
  validates :trigger_type, presence: true, inclusion: {in: TRIGGER_TYPES}

  scope :by_trigger, ->(type) { where(trigger_type: type) }
  scope :visible, -> { where(hidden: false) }
end
