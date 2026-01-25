# == Schema Information
#
# Table name: grid_mobs
# Database name: primary
#
#  id              :integer          not null, primary key
#  description     :text
#  dialogue_tree   :json
#  mob_type        :string
#  name            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  grid_faction_id :integer
#  grid_room_id    :integer
#
class GridMob < ApplicationRecord
  belongs_to :grid_room
  belongs_to :grid_faction, optional: true

  validates :name, presence: true
  validates :mob_type, inclusion: {in: %w[quest_giver vendor lore special], allow_nil: true}
end
