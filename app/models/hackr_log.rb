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
#  timeline      :string           default("2120s"), not null
#  title         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  grid_hackr_id :integer          not null
#
# Indexes
#
#  index_hackr_logs_on_grid_hackr_id  (grid_hackr_id)
#  index_hackr_logs_on_slug           (slug) UNIQUE
#  index_hackr_logs_on_timeline       (timeline)
#
# Foreign Keys
#
#  grid_hackr_id  (grid_hackr_id => grid_hackrs.id)
#
class HackrLog < ApplicationRecord
  has_paper_trail

  belongs_to :grid_hackr

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :body, presence: true
  validates :timeline, presence: true

  scope :published, -> { where(published: true) }
  scope :ordered, -> { order(published_at: :desc, created_at: :desc) }
  scope :for_timeline, ->(t) { where(timeline: t) }
  def self.timelines_summary
    group(:timeline).pluck(
      :timeline,
      Arel.sql("COUNT(*)"),
      Arel.sql("CAST(strftime('%Y', MIN(published_at)) AS INTEGER)"),
      Arel.sql("CAST(strftime('%Y', MAX(published_at)) AS INTEGER)")
    ).each_with_object({}) do |(timeline, count, min_year, max_year), hash|
      hash[timeline] = {
        count: count,
        min_year: min_year ? min_year + 100 : nil,
        max_year: max_year ? max_year + 100 : nil
      }
    end
  end

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
