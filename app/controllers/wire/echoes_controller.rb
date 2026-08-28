# Echo toggle for the Hotwire wire pages (Phase 3) — mirrors
# Api::EchoesController#create (create if missing, destroy if present).
# Responds with the viewer's own echo button; other viewers get the
# count-only update from the model's dual-publish broadcast.
class Wire::EchoesController < ApplicationController
  before_action :require_login

  # POST /wire/pulses/:id/echo
  def create
    @pulse = Pulse.active.find_by(id: params[:id])
    return head :not_found unless @pulse

    existing = Echo.find_by(pulse: @pulse, grid_hackr: current_hackr)
    if existing
      existing.destroy
      @echoed = false
    else
      Echo.create!(pulse: @pulse, grid_hackr: current_hackr)
      @echoed = true
    end
    @pulse.reload

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("pulse_#{@pulse.id}_echo",
          partial: "wire/echo_button", locals: {pulse: @pulse, echoed: @echoed, animate: @echoed})
      end
      format.html { redirect_back fallback_location: wire_path }
    end
  end
end
