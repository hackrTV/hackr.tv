# == Schema Information
#
# Table name: overlay_alerts
# Database name: primary
#
#  id           :integer          not null, primary key
#  alert_type   :string           not null
#  data         :json
#  displayed    :boolean          default(FALSE)
#  displayed_at :datetime
#  expires_at   :datetime
#  message      :text
#  title        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_overlay_alerts_on_alert_type  (alert_type)
#  index_overlay_alerts_on_displayed   (displayed)
#  index_overlay_alerts_on_expires_at  (expires_at)
#
class OverlayAlert < ApplicationRecord
  ALERT_TYPES = %w[subscriber donation raid follow custom].freeze

  # Validations
  validates :alert_type, presence: true, inclusion: {in: ALERT_TYPES}

  # Scopes
  scope :pending, -> { where(displayed: false).where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :displayed, -> { where(displayed: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(alert_type: type) }

  # Queue a new alert and broadcast it
  def self.queue!(type:, title: nil, message: nil, data: {}, expires_in: nil)
    alert = create!(
      alert_type: type,
      title: title,
      message: message,
      data: data,
      expires_at: expires_in ? Time.current + expires_in : nil
    )

    ActionCable.server.broadcast("overlay_updates", {
      type: "new_alert",
      data: alert.as_broadcast_json
    })

    alert
  end

  def mark_displayed!
    update!(displayed: true, displayed_at: Time.current)
  end

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def as_broadcast_json
    {
      id: id,
      alert_type: alert_type,
      title: title,
      message: message,
      data: data,
      created_at: created_at.iso8601
    }
  end
end
