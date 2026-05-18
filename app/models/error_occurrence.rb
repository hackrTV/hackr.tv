# frozen_string_literal: true

# == Schema Information
#
# Table name: error_occurrences
# Database name: primary
#
#  id              :integer          not null, primary key
#  backtrace       :text
#  component       :string           not null
#  exception_class :string
#  hackr_alias     :string
#  ip_address      :string
#  message         :string           not null
#  metadata        :text
#  occurred_at     :datetime         not null
#  rails_env       :string
#  request_method  :string
#  request_params  :text
#  request_url     :string
#  user_agent      :string
#  created_at      :datetime         not null
#  error_group_id  :integer          not null
#  hackr_id        :integer
#
# Indexes
#
#  index_error_occurrences_on_error_group_id                  (error_group_id)
#  index_error_occurrences_on_error_group_id_and_occurred_at  (error_group_id,occurred_at DESC)
#  index_error_occurrences_on_occurred_at                     (occurred_at)
#
# Foreign Keys
#
#  error_group_id  (error_group_id => error_groups.id)
#
class ErrorOccurrence < ApplicationRecord
  belongs_to :error_group

  scope :newest_first, -> { order(occurred_at: :desc) }
  scope :older_than, ->(days) { where("occurred_at < ?", days.days.ago) }

  def parsed_backtrace
    return [] if backtrace.blank?
    JSON.parse(backtrace)
  rescue JSON::ParserError
    []
  end

  def parsed_metadata
    return {} if metadata.blank?
    JSON.parse(metadata)
  rescue JSON::ParserError
    {}
  end

  def parsed_request_params
    return {} if request_params.blank?
    JSON.parse(request_params)
  rescue JSON::ParserError
    {}
  end
end
