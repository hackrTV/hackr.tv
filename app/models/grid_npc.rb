class GridNpc < ApplicationRecord
  belongs_to :grid_room
  belongs_to :grid_faction, optional: true

  validates :name, presence: true
  validates :npc_type, inclusion: {in: %w[quest_giver vendor lore special], allow_nil: true}
end
