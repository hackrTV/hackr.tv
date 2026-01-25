# == Schema Information
#
# Table name: hackr_logs
# Database name: primary
#
#  id            :integer          not null, primary key
#  body          :text             not null
#  published     :boolean          default(FALSE), not null
#  published_at  :datetime
#  slug          :string           not null
#  title         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  grid_hackr_id :integer          not null
#
# Indexes
#
#  index_hackr_logs_on_grid_hackr_id  (grid_hackr_id)
#  index_hackr_logs_on_slug           (slug) UNIQUE
#
# Foreign Keys
#
#  grid_hackr_id  (grid_hackr_id => grid_hackrs.id)
#
class HackrLog < ApplicationRecord
  belongs_to :grid_hackr

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :body, presence: true

  scope :published, -> { where(published: true) }
  scope :ordered, -> { order(published_at: :desc, created_at: :desc) }

  def to_param
    slug
  end

  def publish!
    update(published: true, published_at: Time.current) unless published?
  end

  def unpublish!
    update(published: false) if published?
  end
end
