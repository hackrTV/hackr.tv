# Pulse compose/delete for the Hotwire wire pages (Phase 3). Mirrors
# Api::PulsesController#create/#destroy; the model broadcasts handle the
# live inserts (dual-publish).
class Wire::PulsesController < ApplicationController
  admin_preview! title: "The WIRE"
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
        # Fresh root: its splice_count counter just moved.
        @root = Pulse.find(@pulse.thread_root_id)
        respond_to do |format|
          format.turbo_stream { render :splice } # row into the open thread list + root's ↩ n
          format.html { redirect_to wire_pulse_path(@root) } # see the reply in context
        end
      else
        respond_to do |format|
          format.turbo_stream # prepend own contextual entry + reset composer
          format.html { redirect_to wire_path }
        end
      end
    else
      error = @pulse.errors.full_messages.to_sentence
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(error_slot_id,
            partial: "wire/composer_error", locals: {id: error_slot_id, error: error}), status: :unprocessable_entity
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
      format.turbo_stream { render turbo_stream: turbo_stream.remove("pulse_#{pulse.id}_entry") }
      format.html { redirect_back fallback_location: wire_path }
    end
  end

  private

  # A failed splice reports under its thread's prompt; a failed root
  # pulse under the feed prompt. The thread root is resolved from the
  # parent because the unsaved pulse has no thread_root_id yet.
  def error_slot_id
    parent = Pulse.find_by(id: params[:parent_pulse_id].presence)
    parent ? "pulse_#{parent.thread_root_id || parent.id}_reply_error" : "composer-error"
  end
end
