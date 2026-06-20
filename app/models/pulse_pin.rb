# frozen_string_literal: true

# A hackr pinning one of their own pulses to the top of their WIRE
# profile. Capped at MAX_PINS, ordered by `position` (ascending).
# == Schema Information
#
# Table name: pulse_pins
# Database name: primary
#
#  id            :integer          not null, primary key
#  position      :integer          default(0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  grid_hackr_id :integer          not null
#  pulse_id      :integer          not null
#
# Indexes
#
#  index_pulse_pins_on_grid_hackr_id               (grid_hackr_id)
#  index_pulse_pins_on_grid_hackr_id_and_position  (grid_hackr_id,position)
#  index_pulse_pins_on_grid_hackr_id_and_pulse_id  (grid_hackr_id,pulse_id) UNIQUE
#  index_pulse_pins_on_pulse_id                    (pulse_id)
#
# Foreign Keys
#
#  grid_hackr_id  (grid_hackr_id => grid_hackrs.id)
#  pulse_id       (pulse_id => pulses.id)
#
class PulsePin < ApplicationRecord
  MAX_PINS = 3

  belongs_to :grid_hackr
  belongs_to :pulse

  validates :pulse_id, uniqueness: {scope: :grid_hackr_id}
  validate :pulse_authored_by_pinner
  validate :pulse_not_signal_dropped
  validate :within_pin_limit, on: :create

  scope :ordered, -> { order(:position) }

  private

  def pulse_authored_by_pinner
    return if pulse.nil? || grid_hackr_id.nil?
    return if pulse.grid_hackr_id == grid_hackr_id

    errors.add(:pulse, "must be one of your own pulses")
  end

  def pulse_not_signal_dropped
    return if pulse.nil?
    return unless pulse.signal_dropped?

    errors.add(:pulse, "cannot pin a signal-dropped pulse")
  end

  def within_pin_limit
    return if grid_hackr_id.nil?
    return if PulsePin.where(grid_hackr_id: grid_hackr_id).count < MAX_PINS

    errors.add(:base, "You can pin at most #{MAX_PINS} pulses")
  end
end
