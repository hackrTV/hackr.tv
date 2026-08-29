# Server-rendered home page (Hotwire migration Phase 3) — ports
# HomePage.tsx. Stream state renders at page load; the stream-status
# Stimulus controller refreshes the page on go-live/end broadcasts, and
# stream-watch ports the watch-time heartbeat subscription.
class HomeController < ApplicationController
  layout "hotwire"

  def show
    @live = HackrStream.current_live
    @next_scheduled = HackrStream.next_scheduled
  end
end
