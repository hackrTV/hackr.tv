require "rails_helper"

# /root/uplink channels: the index grouped the way the Uplink sidebar
# renders (category headings, channels by position inside), new/create,
# the edit form with its fixed slug, the category datalist, ↑/↓ swaps
# inside a group and the active toggle.
RSpec.describe "Admin uplink channels", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:channel) { create(:chat_channel, slug: "ambient", name: "#ambient", category: "COMMS", position: 10) }

  before { post "/grid/login", params: {hackr_alias: admin.hackr_alias, password: "hackthegrid"} }

  def row(name)
    %(<strong class="cyan-255-text">#{name}</strong>)
  end

  describe "the index" do
    it "lists channels under their category headings in sidebar order, with ↑/↓ disabled at a group's edges, a toggle per row and a New Channel button" do
      create(:chat_channel, slug: "live", name: "#live", category: "BROADCAST", position: 0)
      ops = create(:chat_channel, slug: "ops", name: "#ops", category: "COMMS", position: 20, is_active: false)

      get "/root/uplink"

      body = response.body
      expect(body).to include("▸ BROADCAST", "▸ COMMS")
      expect([body.index("▸ BROADCAST"), body.index(row("#live")), body.index("▸ COMMS"), body.index(row("#ambient")), body.index(row("#ops"))]).to eq(
        [body.index("▸ BROADCAST"), body.index(row("#live")), body.index("▸ COMMS"), body.index(row("#ambient")), body.index(row("#ops"))].sort
      )
      expect(body).to include("1 channel", "2 channels", "#10", "#20")
      expect(body).to include('href="/root/uplink/channels/new"')
      # #live alone in BROADCAST: both arrows disabled. #ambient first of COMMS: ↑ off, ↓ on; #ops last: the reverse.
      expect(body[/<form[^>]*action="\/root\/uplink\/channels\/live\/move\?direction=up"[^>]*>.*?<\/form>/m]).to include("disabled")
      expect(body[/<form[^>]*action="\/root\/uplink\/channels\/live\/move\?direction=down"[^>]*>.*?<\/form>/m]).to include("disabled")
      expect(body[/<form[^>]*action="\/root\/uplink\/channels\/ambient\/move\?direction=up"[^>]*>.*?<\/form>/m]).to include("disabled")
      expect(body[/<form[^>]*action="\/root\/uplink\/channels\/ambient\/move\?direction=down"[^>]*>.*?<\/form>/m]).not_to include("disabled")
      expect(body[/<form[^>]*action="\/root\/uplink\/channels\/ops\/move\?direction=up"[^>]*>.*?<\/form>/m]).not_to include("disabled")
      expect(body[/<form[^>]*action="\/root\/uplink\/channels\/ops\/move\?direction=down"[^>]*>.*?<\/form>/m]).to include("disabled")
      expect(body[/<form[^>]*action="\/root\/uplink\/channels\/ambient\/toggle"[^>]*>.*?<\/form>/m]).to include("Deactivate")
      expect(body[/<form[^>]*action="\/root\/uplink\/channels\/ops\/toggle"[^>]*>.*?<\/form>/m]).to include("Activate")
      expect(ops.reload.is_active).to be(false)
    end
  end

  describe "new + create" do
    it "offers the groups in use in a datalist and defaults the position to the end of the sidebar" do
      create(:chat_channel, slug: "live", name: "#live", category: "BROADCAST", position: 0)

      get "/root/uplink/channels/new"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('name="chat_channel[slug]"')
      expect(response.body).to include('list="channel-categories"', '<datalist id="channel-categories">', '<option value="BROADCAST">', '<option value="COMMS">')
      expect(response.body).to include('name="chat_channel[position]"').and include('value="20"')
      expect(response.body).to include("Create Channel")
    end

    it "creates the channel (category upcased) and the Uplink sidebar shows it under its heading" do
      post "/root/uplink/channels", params: {chat_channel: {slug: "ops", name: "#ops", description: "Operations.", category: "ops room", position: "30", minimum_role: "operator"}}

      expect(response).to redirect_to("/root/uplink")
      expect(ChatChannel.find_by(slug: "ops")).to have_attributes(name: "#ops", category: "OPS ROOM", position: 30, minimum_role: "operator", is_active: true)
      follow_redirect!
      expect(response.body).to include("Channel #ops created under OPS ROOM.", "▸ OPS ROOM")

      get "/uplink"
      expect(response.body).to include("OPS ROOM", "#ops")
    end

    it "re-renders the form with the error on a bad or taken slug" do
      post "/root/uplink/channels", params: {chat_channel: {slug: "Bad Slug", name: "#bad"}}
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Failed to create channel", "only allows lowercase letters", 'name="chat_channel[slug]"')

      post "/root/uplink/channels", params: {chat_channel: {slug: "ambient", name: "#twice"}}
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Slug has already been taken")
      expect(ChatChannel.count).to eq(1)
    end
  end

  describe "edit + update" do
    it "shows the slug fixed (no input), the sidebar fields with the datalist, and lists them on the index" do
      get "/root/uplink/channels/ambient/edit"

      expect(response.body).not_to include('name="chat_channel[slug]"')
      expect(response.body).to include("/uplink?channel=ambient", "SIDEBAR CATEGORY", 'name="chat_channel[category]"', 'list="channel-categories"', '<option value="COMMS">')
      expect(response.body).to include('name="chat_channel[position]"', "Save Changes")

      get "/root/uplink"
      expect(response.body).to include("▸ COMMS", "#10")
    end

    it "updates category (upcased) and position" do
      patch "/root/uplink/channels/ambient", params: {chat_channel: {name: "#ambient", category: "ops room", position: "3"}}

      expect(response).to redirect_to("/root/uplink")
      expect(channel.reload).to have_attributes(category: "OPS ROOM", position: 3)
    end

    it "rejects a bad category and re-renders the form" do
      patch "/root/uplink/channels/ambient", params: {chat_channel: {name: "#ambient", category: "no/slash"}}

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Failed to update channel")
      expect(channel.reload.category).to eq("COMMS")
    end

    it "never takes a slug on update" do
      patch "/root/uplink/channels/ambient", params: {chat_channel: {slug: "renamed", name: "#ambient"}}

      expect(response).to redirect_to("/root/uplink")
      expect(channel.reload.slug).to eq("ambient")
    end
  end

  describe "move (↑/↓)" do
    let!(:live) { create(:chat_channel, slug: "live", name: "#live", category: "BROADCAST", position: 0) }
    let!(:ops) { create(:chat_channel, slug: "ops", name: "#ops", category: "COMMS", position: 20) }

    it "swaps the channel with its neighbour inside its category and renumbers the sidebar in steps of 10" do
      post "/root/uplink/channels/ops/move", params: {direction: "up"}

      expect(response).to redirect_to("/root/uplink")
      expect(ChatChannel.ordered.pluck(:slug, :position)).to eq([["live", 0], ["ops", 10], ["ambient", 20]])
      follow_redirect!
      expect(response.body).to include("Channel #ops moved up, past #ambient, in COMMS.")
    end

    it "stays put at the group's edge — a move never crosses into another heading" do
      post "/root/uplink/channels/live/move", params: {direction: "down"}

      expect(response).to redirect_to("/root/uplink")
      expect(ChatChannel.ordered.pluck(:slug)).to eq(%w[live ambient ops])
      follow_redirect!
      expect(response.body).to include("Channel #live is already at the bottom of BROADCAST.")
    end

    it "refuses an unknown direction" do
      post "/root/uplink/channels/ops/move", params: {direction: "sideways"}

      expect(response).to redirect_to("/root/uplink")
      expect(flash[:error]).to eq("Move direction must be up or down.")
      expect(ChatChannel.ordered.pluck(:slug)).to eq(%w[live ambient ops])
    end
  end

  describe "toggle" do
    it "flips is_active from the index" do
      post "/root/uplink/channels/ambient/toggle"
      expect(response).to redirect_to("/root/uplink")
      expect(channel.reload.is_active).to be(false)
      follow_redirect!
      expect(response.body).to include("Channel #ambient deactivated.")

      post "/root/uplink/channels/ambient/toggle"
      expect(channel.reload.is_active).to be(true)
    end
  end

  it "keeps the channel tools behind the admin gate" do
    delete "/grid/logout"
    operator = create(:grid_hackr, :operator, password: "hackthegrid")
    post "/grid/login", params: {hackr_alias: operator.hackr_alias, password: "hackthegrid"}

    get "/root/uplink/channels/new"
    expect(response).not_to have_http_status(:ok)
    post "/root/uplink/channels", params: {chat_channel: {slug: "ops", name: "#ops"}}
    expect(ChatChannel.find_by(slug: "ops")).to be_nil
    post "/root/uplink/channels/ambient/toggle"
    expect(channel.reload.is_active).to be(true)
  end
end
