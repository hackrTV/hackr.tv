# == Schema Information
#
# Table name: grid_hackr_achievements
# Database name: primary
#
#  id                  :integer          not null, primary key
#  awarded_at          :datetime         not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  grid_achievement_id :integer          not null
#  grid_hackr_id       :integer          not null
#
# Indexes
#
#  index_grid_hackr_achievements_on_grid_achievement_id  (grid_achievement_id)
#  index_grid_hackr_achievements_on_grid_hackr_id        (grid_hackr_id)
#  index_hackr_achievements_unique                       (grid_hackr_id,grid_achievement_id) UNIQUE
#
# Foreign Keys
#
#  grid_achievement_id  (grid_achievement_id => grid_achievements.id)
#  grid_hackr_id        (grid_hackr_id => grid_hackrs.id)
#
class GridHackrAchievement < ApplicationRecord
  belongs_to :grid_hackr
  belongs_to :grid_achievement

  validates :grid_achievement_id, uniqueness: {scope: :grid_hackr_id}

  before_validation { self.awarded_at ||= Time.current }
end
