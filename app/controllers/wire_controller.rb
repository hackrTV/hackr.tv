# Server-rendered PulseWire pages (Hotwire migration Phase 3) — ports
# HotwirePage.tsx (/wire), UserPulsesPage.tsx (/wire/:username) and
# SinglePulsePage.tsx (/wire/pulse/:id). The JSON API stays for the
# overlay + remaining SPA pages until Phase 7.
class WireController < ApplicationController
  PER_PAGE = 50
  PROFILE_PER_PAGE = 100

  def index
    @page = [params[:page].to_i, 1].max
    @pulses = Pulse.active.roots.timeline.includes(:grid_hackr)
      .limit(PER_PAGE).offset((@page - 1) * PER_PAGE)
    @more = Pulse.active.roots.count > @page * PER_PAGE
    @echoed_ids = echoed_ids_for(@pulses)
  end

  def profile
    @hackr = GridHackr.where("LOWER(hackr_alias) = ?", params[:username].downcase).first
    return render :profile_not_found, status: :not_found unless @hackr

    @is_self = logged_in? && current_hackr.id == @hackr.id
    @stats = Grid::ProfileStats.for(@hackr)
    @pinned = @hackr.pulse_pins.order(:position).includes(pulse: :grid_hackr)
      .map(&:pulse).reject(&:signal_dropped?)

    own = Pulse.active.where(grid_hackr: @hackr).timeline
      .includes(:grid_hackr).limit(PROFILE_PER_PAGE).to_a
    echoed = Pulse.active.joins(:echoes).where(echoes: {grid_hackr_id: @hackr.id})
      .includes(:grid_hackr).to_a

    pinned_ids = @pinned.map(&:id).to_set
    @timeline = build_profile_timeline(own, echoed, pinned_ids)
    @echoed_ids = echoed_ids_for(@timeline.map(&:first) + @pinned)
  end

  def pulse
    @pulse = Pulse.includes(:grid_hackr).find_by(id: params[:id])
    return render :pulse_not_found, status: :not_found unless @pulse

    @root = @pulse.thread_root || @pulse
    @thread = @root.thread_pulses.includes(:grid_hackr).to_a
    @children = @thread.group_by(&:parent_pulse_id)
    @echoed_ids = echoed_ids_for(@thread)
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
