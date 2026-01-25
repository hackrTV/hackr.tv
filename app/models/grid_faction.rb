# == Schema Information
#
# Table name: grid_factions
# Database name: primary
#
#  id           :integer          not null, primary key
#  color_scheme :string
#  description  :text
#  name         :string
#  slug         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  artist_id    :integer
#
class GridFaction < ApplicationRecord
  belongs_to :artist, optional: true

  has_many :grid_zones
  has_many :grid_rooms, through: :grid_zones
  has_many :grid_mobs

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
end
