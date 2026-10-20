require "rails_helper"

# Presence rows behind the Uplink operatives roster + mining presence:
# one row per hackr per channel, created on subscribe, kept alive by the
# periodic touch, removed only by the hackr's LAST unsubscribe (the shell
# plus a popout, or two tabs, share a row). The JSON payloads relay and
# synthia consume are pinned alongside.
RSpec.describe LiveChatChannel, type: :channel do
  let!(:channel) { create(:chat_channel, slug: "ambient") }
  let(:hackr) { create(:grid_hackr) }

  def presence_rows
    GridUplinkPresence.valid.in_channel(channel)
  end

  it "subscribes with the recent packets + presence count, tracking a presence row" do
    create(:chat_message, chat_channel: channel, grid_hackr: hackr, content: "already here")
    stub_connection current_hackr: hackr

    subscribe(chat_channel: "ambient")

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from("uplink:ambient")
    initial = transmissions.first.deep_symbolize_keys
    expect(initial[:type]).to eq("initial_packets")
    expect(initial[:packets].map { |p| p[:content] }).to eq(["already here"])
    expect(initial[:packets].first[:grid_hackr]).to include(hackr_alias: hackr.hackr_alias, role: "operative")
    expect(initial).to include(:presence_count)
    expect(presence_rows.pluck(:grid_hackr_id)).to eq([hackr.id])

    # Close it: the subscription refcount is class-level, and SQLite reuses
    # rolled-back ids, so an open subscription would leak into the next example.
    subscription.unsubscribe_from_channel
    expect(presence_rows.count).to eq(0)
  end

  it "keeps the presence row until the hackr's last subscription to the channel ends" do
    stub_connection current_hackr: hackr
    subscribe(chat_channel: "ambient")
    popout = described_class.new(connection, "{id: 2}", chat_channel: "ambient")
    popout.subscribe_to_channel
    expect(presence_rows.count).to eq(1)

    popout.unsubscribe_from_channel
    expect(presence_rows.count).to eq(1) # the shell is still open

    subscription.unsubscribe_from_channel
    expect(presence_rows.count).to eq(0)
  end

  it "rejects blacked-out hackrs without a presence row" do
    create(:user_punishment, :blackout, grid_hackr: hackr)
    stub_connection current_hackr: hackr

    subscribe(chat_channel: "ambient")

    expect(subscription).to be_rejected
    expect(presence_rows.count).to eq(0)
  end

  it "lets anonymous viewers read livestream channels only" do
    live = create(:chat_channel, :livestream_only, slug: "live")
    create(:hackr_stream, artist: create(:artist), is_live: true, live_url: "https://www.youtube.com/embed/x")
    stub_connection current_hackr: nil

    subscribe(chat_channel: "ambient")
    expect(subscription).to be_rejected

    subscribe(chat_channel: "live")
    expect(subscription).to be_confirmed
    expect(GridUplinkPresence.in_channel(live).count).to eq(0)
  end
end
