# == Schema Information
#
# Table name: manual_test_results
# Database name: primary
#
#  id                 :integer          not null, primary key
#  article_slug       :string           not null
#  notes              :text
#  status             :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  manual_test_run_id :integer          not null
#
# Indexes
#
#  index_manual_test_results_on_manual_test_run_id  (manual_test_run_id)
#  index_manual_test_results_on_run_and_slug        (manual_test_run_id,article_slug) UNIQUE
#
# Foreign Keys
#
#  manual_test_run_id  (manual_test_run_id => manual_test_runs.id)
#
class ManualTestResult < ApplicationRecord
  STATUSES = %w[pass fail blocked skip].freeze

  belongs_to :manual_test_run

  validates :article_slug, presence: true,
    uniqueness: {scope: :manual_test_run_id}
  validates :status, inclusion: {in: STATUSES}

  scope :failed, -> { where(status: "fail") }
end
