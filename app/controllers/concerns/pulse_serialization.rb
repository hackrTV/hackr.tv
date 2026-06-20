# frozen_string_literal: true

# Shared JSON serializer for Pulse records, used by any API controller
# that emits pulses (timeline, profile header, pinned pulses). Viewer-
# specific flags rely on `current_hackr`/`logged_in?` from
# GridAuthentication, so including controllers must also include it.
module PulseSerialization
  extend ActiveSupport::Concern

  private

  # A hackr's pinned pulses in display order, profanity/serialization
  # shared with the timeline. Signal-dropped pulses are hidden.
  def pinned_pulses_json(hackr)
    hackr.pinned_pulses
      .where(signal_dropped: false)
      .includes(:grid_hackr)
      .map { |pulse| pulse_json(pulse) }
  end

  def pulse_json(pulse)
    {
      id: pulse.id,
      content: pulse.content,
      pulsed_at: pulse.pulsed_at,
      echo_count: pulse.echo_count,
      splice_count: pulse.splices.count, # Real-time count
      signal_dropped: pulse.signal_dropped,
      signal_dropped_at: pulse.signal_dropped_at,
      parent_pulse_id: pulse.parent_pulse_id,
      thread_root_id: pulse.thread_root_id,
      is_splice: pulse.is_splice?,
      is_echoed_by_current_hackr: logged_in? ? pulse.is_echo_by?(current_hackr) : false,
      current_hackr_is_logged_in: logged_in?,
      current_hackr_is_admin: logged_in? ? current_hackr.admin? : false,
      grid_hackr: {
        id: pulse.grid_hackr.id,
        hackr_alias: pulse.grid_hackr.hackr_alias,
        role: pulse.grid_hackr.role
      },
      created_at: pulse.created_at,
      updated_at: pulse.updated_at
    }
  end
end
