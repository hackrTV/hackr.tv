# One admin pass through the manual test guide (docs/testing/*.md,
# rendered at /root/test_guide). Results record one status per article.
# == Schema Information
#
# Table name: manual_test_runs
# Database name: primary
#
#  id            :integer          not null, primary key
#  completed_at  :datetime
#  label         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  grid_hackr_id :integer          not null
#
# Indexes
#
#  index_manual_test_runs_on_grid_hackr_id  (grid_hackr_id)
#
# Foreign Keys
#
#  grid_hackr_id  (grid_hackr_id => grid_hackrs.id)
#
class ManualTestRun < ApplicationRecord
  belongs_to :grid_hackr
  has_many :manual_test_results, dependent: :destroy

  validates :label, presence: true

  scope :open_runs, -> { where(completed_at: nil).order(created_at: :desc) }

  def self.active
    open_runs.first
  end

  def completed?
    completed_at.present?
  end

  def result_for(slug)
    manual_test_results.find_by(article_slug: slug)
  end

  def results_by_slug
    manual_test_results.index_by(&:article_slug)
  end

  def progress(total_articles)
    done = manual_test_results.count
    total_articles.zero? ? 0 : ((done.to_f / total_articles) * 100).round
  end
end
