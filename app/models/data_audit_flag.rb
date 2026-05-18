# frozen_string_literal: true

# == Schema Information
#
# Table name: data_audit_flags
# Database name: primary
#
#  id               :integer          not null, primary key
#  check_name       :string           not null
#  domain           :string           not null
#  fingerprint      :string           not null
#  first_flagged_at :datetime         not null
#  last_seen_at     :datetime         not null
#  severity         :string           default("warning"), not null
#  snooze_until     :datetime
#  status           :string           default("open"), not null
#  subject_type     :string
#  title            :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  subject_id       :integer
#
# Indexes
#
#  index_data_audit_flags_on_check_name                   (check_name)
#  index_data_audit_flags_on_domain                       (domain)
#  index_data_audit_flags_on_fingerprint                  (fingerprint) UNIQUE
#  index_data_audit_flags_on_status_and_severity          (status,severity)
#  index_data_audit_flags_on_subject_type_and_subject_id  (subject_type,subject_id)
#
class DataAuditFlag < ApplicationRecord
  STATUSES = %w[open acknowledged].freeze
  SEVERITIES = %w[critical warning info].freeze
  DOMAINS = %w[grid music].freeze

  validates :fingerprint, presence: true, uniqueness: true
  validates :title, presence: true
  validates :check_name, presence: true
  validates :severity, inclusion: {in: SEVERITIES}
  validates :domain, inclusion: {in: DOMAINS}
  validates :status, inclusion: {in: STATUSES}

  scope :open_status, -> { where(status: "open") }
  scope :acknowledged, -> { where(status: "acknowledged") }
  scope :for_severity, ->(s) { where(severity: s) if s.present? }
  scope :for_domain, ->(d) { where(domain: d) if d.present? }
  scope :for_check, ->(c) { where(check_name: c) if c.present? }
  scope :newest_first, -> { order(last_seen_at: :desc) }

  # Flags that should be visible as "open" — either actually open,
  # or acknowledged with an expired snooze.
  scope :effective_open, -> {
    where(status: "open")
      .or(where(status: "acknowledged").where("snooze_until IS NOT NULL AND snooze_until < ?", Time.current))
  }

  def effective_status
    if status == "acknowledged" && snooze_until.present? && snooze_until < Time.current
      "open"
    else
      status
    end
  end

  def snooze_expired?
    status == "acknowledged" && snooze_until.present? && snooze_until < Time.current
  end

  def acknowledge!(until_time = nil)
    update!(status: "acknowledged", snooze_until: until_time)
  end

  def reopen!
    update!(status: "open", snooze_until: nil)
  end
end
