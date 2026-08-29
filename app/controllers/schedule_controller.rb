# Server-rendered stream schedule (Hotwire migration Phase 1) — ports
# StreamSchedulePage.tsx over the same queries as Api::HackrStreamsController#schedule.
class ScheduleController < ApplicationController
  layout "hotwire"

  STATE_BADGES = {
    "upcoming" => {label: "UPCOMING", color: "#06b6d4"},
    "starting_soon" => {label: "STARTING SOON", color: "#f59e0b"},
    "live" => {label: "LIVE", color: "#00ff00"},
    "ended" => {label: "ENDED", color: "#666"},
    "cancelled" => {label: "CANCELLED", color: "#ff4444"},
    "expired" => {label: "EXPIRED", color: "#888"},
    "unscheduled" => {label: "ON-DEMAND", color: "#888"}
  }.freeze

  def show
    @upcoming = HackrStream.includes(:artist).upcoming.limit(20)
    @past = HackrStream.includes(:artist).past_broadcasts.limit(20)
  end
end
