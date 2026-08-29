# Pulse compose/delete for the Hotwire wire pages (Phase 3). Mirrors
# Api::PulsesController#create/#destroy; the model broadcasts handle the
# live inserts (dual-publish).
class Wire::PulsesController < ApplicationController
  layout "hotwire"

  before_action :require_login

  # POST /wire/pulses
  def create
    @pulse = current_hackr.pulses.build(
      content: params[:content],
      parent_pulse_id: params[:parent_pulse_id].presence
    )

    if @pulse.save
      # Root-pulse achievement check — same trigger site as the API.
      unless @pulse.is_splice?
        Grid::AchievementChecker.new(current_hackr).check("wire_pulses_count")
      end

      if @pulse.is_splice?
        # See the reply in context on its thread page.
        redirect_to wire_pulse_path(@pulse.thread_root_id || @pulse.parent_pulse_id)
      else
        respond_to do |format|
          format.turbo_stream # prepend own contextual card + reset composer
          format.html { redirect_to wire_path }
        end
      end
    else
      error = @pulse.errors.full_messages.to_sentence
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("composer-error",
            partial: "wire/composer_error", locals: {error: error}), status: :unprocessable_entity
        end
        format.html { redirect_to wire_path, flash: {error: error} }
      end
    end
  end

  # DELETE /wire/pulses/:id
  def destroy
    pulse = current_hackr.pulses.find_by(id: params[:id])
    return head :not_found unless pulse

    pulse.destroy # broadcast_remove_to handles every subscribed page

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("pulse_#{pulse.id}") }
      format.html { redirect_back fallback_location: wire_path }
    end
  end
end
