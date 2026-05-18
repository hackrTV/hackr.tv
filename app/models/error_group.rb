# frozen_string_literal: true

# == Schema Information
#
# Table name: error_groups
# Database name: primary
#
#  id                   :integer          not null, primary key
#  component            :string           not null
#  fingerprint          :string           not null
#  first_seen_at        :datetime
#  ignore_until         :datetime
#  last_seen_at         :datetime
#  occurrence_count     :integer          default(0), not null
#  resolved_at          :datetime
#  severity             :string           default("error"), not null
#  status               :string           default("open"), not null
#  title                :string           not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  resolved_by_hackr_id :integer
#
# Indexes
#
#  index_error_groups_on_component                (component)
#  index_error_groups_on_fingerprint              (fingerprint) UNIQUE
#  index_error_groups_on_severity                 (severity)
#  index_error_groups_on_status_and_last_seen_at  (status,last_seen_at)
#
class ErrorGroup < ApplicationRecord
  STATUSES = %w[open resolved ignored].freeze
  COMPONENTS = %w[backend frontend].freeze
  SEVERITIES = %w[error warning info].freeze

  has_many :error_occurrences, dependent: :destroy
  belongs_to :resolved_by_hackr, class_name: "GridHackr", optional: true

  validates :fingerprint, presence: true, uniqueness: true
  validates :title, presence: true
  validates :component, inclusion: {in: COMPONENTS}
  validates :severity, inclusion: {in: SEVERITIES}
  validates :status, inclusion: {in: STATUSES}

  scope :open_status, -> { where(status: "open") }
  scope :resolved, -> { where(status: "resolved") }
  scope :ignored, -> { where(status: "ignored") }
  scope :for_component, ->(c) { where(component: c) if c.present? }
  scope :for_severity, ->(s) { where(severity: s) if s.present? }
  scope :newest_first, -> { order(last_seen_at: :desc) }

  def effective_status
    if status == "ignored" && ignore_until.present? && ignore_until < Time.current
      "open"
    else
      status
    end
  end

  def ignore_expired?
    status == "ignored" && ignore_until.present? && ignore_until < Time.current
  end

  def resolve!(hackr)
    update!(status: "resolved", resolved_at: Time.current, resolved_by_hackr: hackr)
  end

  def ignore!(until_time = nil)
    update!(status: "ignored", ignore_until: until_time)
  end

  def reopen!
    update!(status: "open", resolved_at: nil, resolved_by_hackr: nil, ignore_until: nil)
  end
end
