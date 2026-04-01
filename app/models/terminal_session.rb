# frozen_string_literal: true

# == Schema Information
#
# Table name: terminal_sessions
# Database name: primary
#
#  id                :integer          not null, primary key
#  connected_at      :datetime         not null
#  disconnect_reason :string
#  disconnected_at   :datetime
#  duration_seconds  :integer
#  ip_address        :string
#  grid_hackr_id     :integer
#
# Indexes
#
#  index_terminal_sessions_on_connected_at   (connected_at)
#  index_terminal_sessions_on_grid_hackr_id  (grid_hackr_id)
#  index_terminal_sessions_on_ip_address     (ip_address)
#
# Foreign Keys
#
#  grid_hackr_id  (grid_hackr_id => grid_hackrs.id)
#
class TerminalSession < ApplicationRecord
  belongs_to :grid_hackr, optional: true
  has_many :terminal_events, dependent: :delete_all

  scope :recent, ->(limit = 50) { order(connected_at: :desc).limit(limit) }
  scope :by_ip, ->(ip) { where(ip_address: ip) }
  scope :by_hackr, ->(hackr_id) { where(grid_hackr_id: hackr_id) }
  scope :since, ->(time) { where("connected_at >= ?", time) }
  scope :active, -> { where(disconnected_at: nil) }

  def close!(reason: "normal")
    update!(
      disconnected_at: Time.current,
      duration_seconds: (Time.current - connected_at).to_i,
      disconnect_reason: reason
    )
  end
end
