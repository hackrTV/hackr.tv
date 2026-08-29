module FeedHelper
  # WorldFeedPage.tsx EVENT_COLORS.
  EVENT_COLORS = {
    "clearance_up" => "#fbbf24",
    "mission_accepted" => "#22d3ee",
    "mission_completed" => "#34d399",
    "breach_completed" => "#f97316",
    "rep_tier_changed" => "#a78bfa",
    "achievement_unlocked" => "#fbbf24",
    "hackr_registered" => "#22d3ee",
    "wire_post" => "#9ca3af",
    "manual" => "#d0d0d0"
  }.freeze

  def feed_event_color(event_type)
    EVENT_COLORS.fetch(event_type, "#d0d0d0")
  end
end
