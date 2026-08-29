# Pin management for own profile (Phase 3) — mirrors
# Api::PulsePinsController (max-3 cap under with_lock, resequencing on
# destroy, reorder). Responses replace the profile's pinned box +
# timeline so pin state stays consistent everywhere on the page.
class Wire::PinsController < ApplicationController
  layout "hotwire"

  before_action :require_login

  # POST /wire/pulses/:id/pin
  def create
    pulse = current_hackr.pulses.active.find_by(id: params[:id])
    return head :not_found unless pulse

    error = nil
    current_hackr.with_lock do
      if current_hackr.pulse_pins.count >= PulsePin::MAX_PINS
        error = "You can pin at most #{PulsePin::MAX_PINS} pulses"
      elsif !current_hackr.pulse_pins.exists?(pulse: pulse)
        position = (current_hackr.pulse_pins.maximum(:position) || -1) + 1
        current_hackr.pulse_pins.create!(pulse: pulse, position: position)
      end
    end

    redirect_to_profile(error: error)
  end

  # DELETE /wire/pulses/:id/pin
  def destroy
    pin = current_hackr.pulse_pins.find_by(pulse_id: params[:id])
    pin&.destroy # after_destroy resequences

    redirect_to_profile
  end

  # PATCH /wire/pulses/:id/pin/move  (direction: up|down)
  def move
    pins = current_hackr.pulse_pins.order(:position).to_a
    idx = pins.index { |p| p.pulse_id == params[:id].to_i }
    if idx
      swap = (params[:direction] == "up") ? idx - 1 : idx + 1
      if swap.between?(0, pins.length - 1)
        PulsePin.transaction do
          a, b = pins[idx], pins[swap]
          a_pos, b_pos = a.position, b.position
          a.update!(position: -1) # dodge any unique index during the swap
          b.update!(position: a_pos)
          a.update!(position: b_pos)
        end
      end
    end

    redirect_to_profile
  end

  private

  def redirect_to_profile(error: nil)
    flash[:x_pin_error] = error if error
    # Lowercase: profile URLs are canonicalized by LowercaseRedirect —
    # redirecting to the cased alias would bounce through a second 301.
    redirect_to wire_user_path(current_hackr.hackr_alias.downcase)
  end
end
