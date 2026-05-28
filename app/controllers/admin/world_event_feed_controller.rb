# frozen_string_literal: true

class Admin::WorldEventFeedController < Admin::ApplicationController
  # GET /root/world_event_feed
  def index
    @settings = WorldEventSetting.current
    @recent_events = WorldEvent.recent.limit(50)
    @simulants = WorldEventSimulant.includes(:grid_hackr).order("grid_hackrs.hackr_alias").to_a
    @organic_rate = WorldEventFeed::Publisher.current_organic_rate
    @total_events = WorldEvent.count
    @simulated_count = WorldEvent.simulated.count
    @organic_count = WorldEvent.organic.count
  end

  # PATCH /root/world_event_feed/settings
  def update_settings
    settings = WorldEventSetting.current
    if settings.update(settings_params)
      set_flash_success("Settings updated! Target: #{settings.target_events_per_minute}/min, Simulator: #{settings.simulator_enabled? ? "ON" : "OFF"}")
    else
      set_flash_error(settings.errors.full_messages.join(", "))
    end
    redirect_to admin_world_event_feed_index_path
  end

  # POST /root/world_event_feed/publish
  def publish
    hackr_alias = params[:hackr_alias].to_s.strip
    event_type = params[:event_type].to_s.strip

    unless WorldEvent::EVENT_TYPES.include?(event_type)
      set_flash_error("Invalid event type: #{event_type}")
      return redirect_to admin_world_event_feed_index_path
    end

    # Admin can only publish events for simulant accounts
    simulant = WorldEventSimulant.joins(:grid_hackr).find_by(grid_hackrs: {hackr_alias: hackr_alias})
    if hackr_alias.present? && simulant.nil?
      set_flash_error("Events can only be published for simulant accounts.")
      return redirect_to admin_world_event_feed_index_path
    end

    data = build_event_data(event_type)
    alias_to_use = hackr_alias.presence || "SYSTEM"

    WorldEventFeed::Publisher.publish(
      event_type: event_type,
      hackr_alias: alias_to_use,
      data: data,
      simulated: true
    )

    set_flash_success("Event published: #{event_type} for #{alias_to_use}")
    redirect_to admin_world_event_feed_index_path
  end

  private

  def settings_params
    params.require(:world_event_setting).permit(:target_events_per_minute, :simulator_enabled, :visible)
  end

  def build_event_data(event_type)
    case event_type
    when "clearance_up"
      {new_clearance: params[:new_clearance].to_i}
    when "mission_accepted", "mission_completed"
      {mission_name: params[:mission_name].to_s}
    when "breach_completed"
      {template_name: params[:template_name].to_s, tier: params[:tier].to_s}
    when "rep_tier_changed"
      {faction_name: params[:faction_name].to_s, new_tier: params[:new_tier].to_s, direction: params[:direction].to_s}
    when "achievement_unlocked"
      {achievement_name: params[:achievement_name].to_s}
    when "wire_post"
      {content: params[:content].to_s.truncate(80)}
    when "manual"
      {message: params[:message].to_s}
    else
      {}
    end
  end
end
