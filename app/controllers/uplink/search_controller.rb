# Packet search for the /uplink shell (Phase 2 item 9). The header's
# [/] SEARCH flips the operatives pane to a search form whose GET lands
# here (Turbo frame uplink-search): the channel's active packets whose
# text contains the query, newest first, capped at RESULT_CAP, each row a
# link to the packet — resolved in place by the uplink-shell controller
# when the log has it, otherwise a visit to /uplink?channel=&around=<id>
# (UplinkController#show opens the log on it). Plain LIKE over the
# channel's rows: SQLite's LIKE is ASCII case-insensitive and the query's
# % and _ are escaped, so they match themselves; FTS5 waits until this
# proves slow. Login + the channel in view, as the log; outside a frame
# (a pasted URL) the request goes to the channel itself.
class Uplink::SearchController < ApplicationController
  before_action :require_login

  RESULT_CAP = 50
  QUERY_MAX = 100 # chars; the field's maxlength

  # GET /uplink/search?channel=&q=
  def show
    return redirect_to uplink_path(channel: params[:channel].presence) unless turbo_frame_request?

    @channel = ChatChannel.active.find_by(slug: params[:channel])
    return refuse(:not_found, "That channel is gone.") unless @channel
    return refuse(:forbidden, "#{@channel.name} is outside your clearance.") unless @channel.viewable_by?(current_hackr)

    @query = self.class.normalize(params[:q])
    rows = @query.blank? ? [] : matches.limit(RESULT_CAP + 1).to_a
    @capped = rows.size > RESULT_CAP
    @results = rows.first(RESULT_CAP)
  end

  # The query as searched: stripped, cut at QUERY_MAX. Shared with the
  # shell, which prefills the field and reloads the results from ?q=.
  def self.normalize(raw)
    raw.to_s.strip.first(QUERY_MAX)
  end

  private

  # One extra row says whether the cap bit. ESCAPE makes the backslash
  # sanitize_sql_like inserts an escape character for SQLite's LIKE.
  def matches
    pattern = "%#{ChatMessage.sanitize_sql_like(@query)}%"
    @channel.chat_messages.active.includes(:grid_hackr)
      .where("chat_messages.content LIKE ? ESCAPE '\\'", pattern)
      .order(id: :desc)
  end

  # Always the frame — Turbo visits a frameless error body as a page — so a
  # miss renders the results' empty state at the real status.
  def refuse(status, message)
    @error = message
    render :show, status: status
  end
end
