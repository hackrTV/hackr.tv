class ScheduleController < ApplicationController
  STATE_BADGES = {
    "upcoming" => {label: "UPCOMING", tone: "sc-state--upcoming"},
    "starting_soon" => {label: "STARTING SOON", tone: "sc-state--soon"}
  }.freeze

  def show
    @live = HackrStream.includes(:artist).current_live
    @upcoming = HackrStream.includes(:artist).upcoming.limit(20).to_a
    @past = HackrStream.includes(:artist).past_broadcasts.limit(20).to_a
  end
end
