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
#  vendor_config   :json
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  grid_faction_id :integer
#  grid_room_id    :integer
#
class GridMob < ApplicationRecord
  belongs_to :grid_room
  belongs_to :grid_faction, optional: true
  has_many :grid_shop_listings, dependent: :destroy
  has_many :grid_shop_transactions, dependent: :nullify

  validates :name, presence: true
  validates :mob_type, inclusion: {in: %w[quest_giver vendor lore special], allow_nil: true}

  def vendor?
    mob_type == "vendor"
  end

  def shop_type
    vendor_config&.dig("shop_type") || "standard"
  end

  def black_market?
    shop_type == "black_market"
  end

  def restock_interval_hours
    vendor_config&.dig("restock_interval_hours") || 24
  end

  def rotation_count
    vendor_config&.dig("rotation_count") || 3
  end
end
