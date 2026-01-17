class Echo < ApplicationRecord
  self.table_name = "echoes"

  belongs_to :pulse, counter_cache: :echo_count
  belongs_to :grid_hackr

  validates :grid_hackr_id, uniqueness: {scope: :pulse_id, message: "has already echoed this pulse"}
  validates :echoed_at, presence: true

  before_validation :set_echoed_at, on: :create
  after_create_commit :broadcast_echo_created
  after_destroy_commit :broadcast_echo_removed

  scope :recent, -> { order(echoed_at: :desc) }

  private

  def set_echoed_at
    self.echoed_at ||= Time.current
  end

  def broadcast_echo_created
    ActionCable.server.broadcast("pulse_wire", {
      type: "echo_created",
      pulse_id: pulse_id,
      hackr_id: grid_hackr_id,
      hackr_alias: grid_hackr&.hackr_alias,
      echo_count: pulse.reload.echo_count
    })
  end

  def broadcast_echo_removed
    # Skip broadcast if pulse was deleted (cascade delete) - pulse_deleted event handles it
    reloaded_pulse = Pulse.find_by(id: pulse_id)
    return unless reloaded_pulse

    ActionCable.server.broadcast("pulse_wire", {
      type: "echo_removed",
      pulse_id: pulse_id,
      hackr_id: grid_hackr_id,
      echo_count: reloaded_pulse.echo_count
    })
  end
end
