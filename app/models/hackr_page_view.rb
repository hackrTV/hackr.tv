# == Schema Information
#
# Table name: hackr_page_views
# Database name: primary
#
#  id            :integer          not null, primary key
#  page_type     :string           not null
#  viewed_at     :datetime         not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  grid_hackr_id :integer          not null
#  resource_id   :integer          not null
#
# Indexes
#
#  index_hackr_page_views_hackr_type        (grid_hackr_id,page_type)
#  index_hackr_page_views_on_grid_hackr_id  (grid_hackr_id)
#  index_hackr_page_views_unique            (grid_hackr_id,page_type,resource_id) UNIQUE
#
# Foreign Keys
#
#  grid_hackr_id  (grid_hackr_id => grid_hackrs.id)
#
# Polymorphic-lite view tracking. `resource_id` is an Artist id when
# page_type is "bio" or "release_index", a Release id when page_type is
# "release". No FK constraint — resource_type is implied by page_type.
class HackrPageView < ApplicationRecord
  PAGE_TYPES = %w[bio release_index release].freeze

  belongs_to :grid_hackr

  validates :page_type, inclusion: {in: PAGE_TYPES}
  validates :resource_id, uniqueness: {scope: [:grid_hackr_id, :page_type]}
  before_validation :set_viewed_at, on: :create

  scope :of_type, ->(type) { where(page_type: type) }

  def self.record!(hackr, page_type, resource_id)
    find_or_create_by!(grid_hackr: hackr, page_type: page_type, resource_id: resource_id) do |r|
      r.viewed_at = Time.current
    end
  rescue ActiveRecord::RecordNotUnique
    find_by!(grid_hackr: hackr, page_type: page_type, resource_id: resource_id)
  end

  private

  def set_viewed_at
    self.viewed_at ||= Time.current
  end
end
