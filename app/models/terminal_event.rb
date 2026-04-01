# frozen_string_literal: true

# == Schema Information
#
# Table name: terminal_events
# Database name: primary
#
#  id                  :integer          not null, primary key
#  event_type          :string           not null
#  handler             :string
#  input               :string
#  metadata            :json
#  created_at          :datetime         not null
#  terminal_session_id :integer          not null
#
# Indexes
#
#  index_terminal_events_on_created_at                          (created_at)
#  index_terminal_events_on_event_type                          (event_type)
#  index_terminal_events_on_terminal_session_id                 (terminal_session_id)
#  index_terminal_events_on_terminal_session_id_and_created_at  (terminal_session_id,created_at)
#
# Foreign Keys
#
#  terminal_session_id  (terminal_session_id => terminal_sessions.id)
#
class TerminalEvent < ApplicationRecord
  belongs_to :terminal_session

  scope :recent, ->(limit = 50) { order(created_at: :desc).limit(limit) }
  scope :by_type, ->(type) { where(event_type: type) }
  scope :commands, -> { where(event_type: "command") }
  scope :auth_failures, -> { where(event_type: "auth_failure") }
  scope :since, ->(time) { where("created_at >= ?", time) }
end
