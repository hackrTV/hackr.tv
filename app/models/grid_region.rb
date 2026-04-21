# == Schema Information
#
# Table name: grid_regions
# Database name: primary
#
#  id          :integer          not null, primary key
#  description :text
#  name        :string           not null
#  slug        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_grid_regions_on_slug  (slug) UNIQUE
#
class GridRegion < ApplicationRecord
  has_paper_trail

  has_many :grid_zones, dependent: :restrict_with_error
  has_many :grid_rooms, through: :grid_zones

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
end
