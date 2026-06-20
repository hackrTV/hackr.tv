module Api
  # Manage the pulses a hackr pins to the top of their WIRE profile.
  # Pins are always the current hackr's own pulses (enforced on the
  # model), capped at PulsePin::MAX_PINS, ordered by `position`.
  class PulsePinsController < ApplicationController
    include GridAuthentication
    include PulseSerialization

    before_action :require_login_api

    # POST /api/pulses/:pulse_id/pin
    def create
      pulse = Pulse.find_by(id: params[:pulse_id])
      return render json: {success: false, error: "Pulse not found"}, status: :not_found unless pulse

      pin = nil
      over_limit = false

      # Lock the hackr row so two concurrent pins can't both pass the cap.
      current_hackr.with_lock do
        if current_hackr.pulse_pins.count >= PulsePin::MAX_PINS
          over_limit = true
        else
          pin = current_hackr.pulse_pins.create(pulse: pulse, position: next_position)
        end
      end

      if over_limit
        render json: {success: false, error: "You can pin at most #{PulsePin::MAX_PINS} pulses"}, status: :unprocessable_entity
      elsif pin&.persisted?
        render json: {success: true, pinned_pulses: pinned_pulses_json(current_hackr)}, status: :created
      else
        render json: {success: false, error: pin&.errors&.full_messages&.to_sentence || "Unable to pin pulse"}, status: :unprocessable_entity
      end
    end

    # DELETE /api/pulses/:pulse_id/pin
    def destroy
      PulsePin.transaction do
        current_hackr.pulse_pins.find_by(pulse_id: params[:pulse_id])&.destroy
        resequence!
      end
      render json: {success: true, pinned_pulses: pinned_pulses_json(current_hackr)}
    end

    # PATCH /api/profile/pins  { pulse_ids: [...] } — set pin order
    def reorder
      requested = Array(params[:pulse_ids]).map(&:to_i).uniq
      pins = current_hackr.pulse_pins.to_a

      # Honor the requested order for known pins, then append any pins the
      # caller omitted (e.g. a concurrently-added pin) so positions stay
      # contiguous and nothing is silently stranded at a stale position.
      ordered = requested.filter_map { |pid| pins.find { |p| p.pulse_id == pid } }
      ordered += (pins - ordered).sort_by(&:position)

      PulsePin.transaction do
        ordered.each_with_index do |pin, idx|
          pin.update_column(:position, idx) unless pin.position == idx
        end
      end

      render json: {success: true, pinned_pulses: pinned_pulses_json(current_hackr)}
    end

    private

    def next_position
      (current_hackr.pulse_pins.maximum(:position) || -1) + 1
    end

    # Close gaps after a removal so positions stay 0..n-1.
    def resequence!
      current_hackr.pulse_pins.ordered.each_with_index do |pin, idx|
        pin.update_column(:position, idx) unless pin.position == idx
      end
    end
  end
end
