require "rails_helper"

# Server-rendered legacy PULSE GRID terminal + command endpoint (Hotwire
# migration Phase 6a). The JSON command API keeps its own spec; the
# dual-publish broadcasts are covered in the RoomEventBroadcaster spec.
RSpec.describe "Grid game pages", type: :request do
  let(:zone) { create(:grid_zone) }
  let(:room) { create(:grid_room, grid_zone: zone, name: "Neon Atrium") }
  let!(:hackr) do
    create(:grid_hackr, password: "hackthegrid", current_room: room,
      stats: {"tutorial_completed" => true})
  end

  def grant_grid!(to = hackr)
    create(:feature_grant, grid_hackr: to, feature: FeatureGrant::PULSE_GRID)
  end

  def log_in!(as = hackr)
    post "/grid/login", params: {hackr_alias: as.hackr_alias, password: "hackthegrid"}
  end

  def turbo_stream_headers
    {"Accept" => "text/vnd.turbo-stream.html"}
  end

  describe "GET /grid" do
    it "requires login" do
      get "/grid"

      expect(response).to have_http_status(:redirect)
      expect(response.location).to include("/grid/login")
    end

    it "renders the coming-soon gate without the pulse_grid grant" do
      log_in!

      get "/grid"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("will open soon")
      expect(response.body).not_to include("grid-command-form")
    end

    it "renders the terminal with the welcome banner, initial look, and room stream" do
      grant_grid!
      log_in!

      get "/grid"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("WELCOME TO THE PULSE GRID")
      expect(response.body).to include("NEON ATRIUM") # inline initial look (look uppercases names)
      expect(response.body).to include("turbo-cable-stream-source")
      expect(response.body).to include(%(data-grid-room-id="#{room.id}"))
      expect(response.body).to include('data-packet-log-cap-value="500"')
      expect(response.body).to include("Enter command")
      expect(response.body).to include("KILLSWITCH")
    end
  end

  describe "POST /grid/commands" do
    it "requires login" do
      post "/grid/commands", params: {input: "look"}

      expect(response).to have_http_status(:redirect)
    end

    it "403s without the pulse_grid grant" do
      log_in!

      post "/grid/commands", params: {input: "look"}, headers: turbo_stream_headers

      expect(response).to have_http_status(:forbidden)
    end

    it "appends the command output to the log" do
      grant_grid!
      log_in!

      post "/grid/commands", params: {input: "look"}, headers: turbo_stream_headers

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      expect(response.body).to include('action="append" target="grid-log"')
      expect(response.body).to include("NEON ATRIUM")
      expect(response.body).not_to include("grid-room-stream") # no move, no swap
    end

    it "swaps the room stream subscription on movement" do
      target = create(:grid_room, grid_zone: zone, name: "Fiber Alley")
      create(:grid_exit, from_room: room, to_room: target, direction: "north", requires_item_id: nil)
      grant_grid!
      log_in!

      post "/grid/commands", params: {input: "go north"}, headers: turbo_stream_headers

      expect(response.body).to include('action="replace" target="grid-room-stream"')
      expect(response.body).to include(%(data-grid-room-id="#{target.id}"))
      expect(response.body).to include("FIBER ALLEY")
      expect(hackr.reload.current_room).to eq(target)
    end
  end

  describe "POST /api/grid/command (envelope lock after CommandRunner extraction)" do
    it "keeps the JSON response shape byte-compatible" do
      grant_grid!
      log_in!

      post "/api/grid/command", params: {input: "look"}, as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.keys).to match_array(%w[success output room_id current_room in_breach breach_meta])
      expect(json["success"]).to be(true)
      expect(json["output"]).to include("NEON ATRIUM")
      expect(json["room_id"]).to eq(room.id)
      expect(json["current_room"]).to include("id" => room.id, "name" => "Neon Atrium")
      expect(json["in_breach"]).to be(false)
      expect(json["breach_meta"]).to be_nil
    end

    it "still broadcasts room events (dual-publish via the shared runner)" do
      grant_grid!
      log_in!
      allow(GridChannel).to receive(:broadcast_to).and_call_original
      allow(Turbo::StreamsChannel).to receive(:broadcast_append_to).and_call_original

      post "/api/grid/command", params: {input: "say hello from the api"}, as: :json

      expect(GridChannel).to have_received(:broadcast_to).with(room, hash_including(type: "say"))
      expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to).with(
        ["grid_room_html", room.id], hash_including(partial: "grid/say_line")
      )
    end
  end
end
