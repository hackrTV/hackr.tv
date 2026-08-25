# Server-rendered World Feed (Hotwire migration Phase 3) — ports
# WorldFeedPage.tsx. Initial render mirrors the channel's last-50
# hydration; live lines append via the Publisher's dual-publish.
class FeedController < ApplicationController
  layout "hotwire"

  before_action :require_feed_visible

  INITIAL_EVENTS = 50

  def show
    @events = WorldEvent.order(created_at: :desc).limit(INITIAL_EVENTS).reverse
  end

  private

  # Mirrors WorldEventFeedChannel's subscription rule: hidden feed is
  # admin-preview only. The SPA redirected to root the same way.
  def require_feed_visible
    return if WorldEventSetting.visible? || admin_hackr?

    redirect_to root_path
  end
end
