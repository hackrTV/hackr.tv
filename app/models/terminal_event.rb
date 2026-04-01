# frozen_string_literal: true

class TerminalEvent < ApplicationRecord
  belongs_to :terminal_session

  scope :recent, ->(limit = 50) { order(created_at: :desc).limit(limit) }
  scope :by_type, ->(type) { where(event_type: type) }
  scope :commands, -> { where(event_type: "command") }
  scope :auth_failures, -> { where(event_type: "auth_failure") }
  scope :since, ->(time) { where("created_at >= ?", time) }
end
