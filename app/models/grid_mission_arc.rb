# == Schema Information
#
# Table name: grid_mission_arcs
# Database name: primary
#
#  id          :integer          not null, primary key
#  description :text
#  name        :string           not null
#  position    :integer          default(0), not null
#  published   :boolean          default(FALSE), not null
#  slug        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_grid_mission_arcs_on_slug  (slug) UNIQUE
#
class GridMissionArc < ApplicationRecord
  has_many :grid_missions, dependent: :nullify

  validates :slug, presence: true, uniqueness: true
  validates :name, presence: true

  scope :published, -> { where(published: true) }
  scope :ordered, -> { order(:position, :name) }

  def to_param
    slug
  end
end
