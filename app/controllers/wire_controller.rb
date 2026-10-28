# Server-rendered PulseWire pages (Hotwire migration Phase 3; ledger rows
# since 2026-10) — /wire (feed), /wire/:username (profile) and
# /wire/pulse/:id (a thread: the deep-link page, or, as a Turbo-Frame
# request, the thread fragment a feed row expands inline). The feed's
# context pane (turbo-frame#wire-pane) asks the same two URLs and gets
# its own renders — the thread with its root in full, the operative
# record without the timeline — keyed on that frame id alone, so other
# frame requests (the bio frame following its redirect) still get the
# page. Two per-browser layout choices ride plain cookies the wire-view
# / wire-pane controllers write (wire_view=mutt, wire_pane=open), so
# the first paint is already the chosen shell: MUTT mode is a second
# render of the feed (wire/_mutt — index + pager, no page chrome).
class WireController < ApplicationController
  admin_preview! title: "The WIRE"

  PER_PAGE = 50
  PROFILE_PER_PAGE = 100

  def index
    @page = [params[:page].to_i, 1].max
    @pulses = Pulse.active.roots.timeline.includes(:grid_hackr)
      .limit(PER_PAGE).offset((@page - 1) * PER_PAGE)
    @total = Pulse.active.roots.count
    @more = @total > @page * PER_PAGE
    @echoed_ids = echoed_ids_for(@pulses)
    @view = (cookies[:wire_view] == "mutt") ? "mutt" : "ledger"
    @pane_open = cookies[:wire_pane] == "open"
  end

  def profile
    @hackr = GridHackr.where("LOWER(hackr_alias) = ?", params[:username].downcase).first
    if turbo_frame_request_id == "wire-pane"
      return render :record_missing, status: :not_found unless @hackr

      @stats = Grid::ProfileStats.for(@hackr)
      return render :record
    end
    return render :profile_not_found, status: :not_found unless @hackr

    @is_self = logged_in? && current_hackr.id == @hackr.id
    @stats = Grid::ProfileStats.for(@hackr)
    @pinned = @hackr.pulse_pins.order(:position).includes(pulse: :grid_hackr)
      .map(&:pulse).reject(&:pulse_dropped?)

    # parent_pulse → grid_hackr feeds a splice row's "[>] re @alias" line.
    own = Pulse.active.where(grid_hackr: @hackr).timeline
      .includes(:grid_hackr, parent_pulse: :grid_hackr).limit(PROFILE_PER_PAGE).to_a
    echoed = Pulse.active.joins(:echoes).where(echoes: {grid_hackr_id: @hackr.id})
      .includes(:grid_hackr, parent_pulse: :grid_hackr).to_a

    pinned_ids = @pinned.map(&:id).to_set
    @timeline = build_profile_timeline(own, echoed, pinned_ids)
    @echoed_ids = echoed_ids_for(@timeline.map(&:first) + @pinned)
  end

  def pulse
    @pulse = Pulse.includes(:grid_hackr).find_by(id: params[:id])
    unless @pulse
      return render :thread_missing, status: :not_found if turbo_frame_request?

      return render :pulse_not_found, status: :not_found
    end

    @root = @pulse.thread_root || @pulse
    @thread = @root.thread_pulses.includes(:grid_hackr).to_a
    @reply_counts = @thread.map(&:parent_pulse_id).tally # direct replies per pulse
    @echoed_ids = echoed_ids_for(@thread)
    # Replies flat + oldest first, each paired with its parent from the
    # loaded thread (no per-row query) — wire/_thread.
    by_id = @thread.index_by(&:id)
    @nodes = @thread.reject { |p| p.id == @root.id }.sort_by(&:pulsed_at)
      .map { |p| [p, by_id[p.parent_pulse_id]] }

    return render :pane if turbo_frame_request_id == "wire-pane"

    render :thread if turbo_frame_request?
  end

  private

  def echoed_ids_for(pulses)
    return Set.new unless logged_in?

    current_hackr.echoes.where(pulse_id: pulses.map(&:id)).pluck(:pulse_id).to_set
  end

  # Own pulses + echoed pulses merged newest-first, tagged with the
  # indicator kind; the pinned box renders once, so pinned own pulses are
  # excluded from the timeline (feed dedup — same as the SPA).
  def build_profile_timeline(own, echoed, pinned_ids)
    own_entries = own.reject { |p| pinned_ids.include?(p.id) }
      .map { |p| [p, p.is_splice? ? :splice : nil, p.pulsed_at] }
    echo_times = Echo.where(grid_hackr_id: @hackr.id, pulse_id: echoed.map(&:id))
      .pluck(:pulse_id, :echoed_at).to_h
    own_ids = own.map(&:id).to_set
    echo_entries = echoed.reject { |p| own_ids.include?(p.id) || pinned_ids.include?(p.id) }
      .map { |p| [p, :echo, echo_times[p.id] || p.pulsed_at] }

    (own_entries + echo_entries).sort_by { |_, _, t| t }.reverse.map { |p, kind, _| [p, kind] }
  end
end
