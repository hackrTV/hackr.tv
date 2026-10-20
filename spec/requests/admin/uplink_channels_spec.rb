require "rails_helper"

# /root/uplink/channels/:slug — the sidebar fields (category + position)
# added for the Uplink shell ride the existing channel edit form.
RSpec.describe "Admin uplink channels", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:channel) { create(:chat_channel, slug: "ambient", name: "#ambient") }

  before { post "/grid/login", params: {hackr_alias: admin.hackr_alias, password: "hackthegrid"} }

  it "shows the sidebar fields on the edit form and lists them on the index" do
    channel.update!(category: "COMMS", position: 10)

    get "/root/uplink/channels/ambient/edit"
    expect(response.body).to include("Sidebar Category")
    expect(response.body).to include('name="chat_channel[category]"')
    expect(response.body).to include('name="chat_channel[position]"')

    get "/root/uplink"
    expect(response.body).to include("COMMS")
    expect(response.body).to include("#10")
  end

  it "updates category (upcased) and position" do
    patch "/root/uplink/channels/ambient", params: {chat_channel: {name: "#ambient", category: "ops room", position: "3"}}

    expect(response).to redirect_to("/root/uplink")
    expect(channel.reload).to have_attributes(category: "OPS ROOM", position: 3)
  end

  it "rejects a bad category and re-renders the form" do
    patch "/root/uplink/channels/ambient", params: {chat_channel: {name: "#ambient", category: "no/slash"}}

    expect(response.body).to include("Failed to update channel")
    expect(channel.reload.category).to eq("COMMS")
  end
end
