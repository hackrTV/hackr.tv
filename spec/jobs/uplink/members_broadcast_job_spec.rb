require "rails_helper"

RSpec.describe Uplink::MembersBroadcastJob, type: :job do
  let(:channel) { create(:chat_channel, slug: "ambient") }

  it "replaces #uplink-members on the channel's members stream with the anonymized roster" do
    hackr = create(:grid_hackr, :operator)
    GridUplinkPresence.touch!(hackr, channel)
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to).and_call_original

    described_class.perform_now(channel.id)

    expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).with(
      ["uplink_members", "ambient"],
      hash_including(target: "uplink-members", partial: "uplink/members")
    ) do |_stream, options|
      html = ApplicationController.render(partial: options[:partial], locals: options[:locals])
      expect(html).to include(Uplink::Callsign.label(hackr.id))
      expect(html).to include("OPERATOR — 1")
      expect(html).not_to include(hackr.hackr_alias)
    end
  end

  it "pushes the channel's sidebar count with the same render: on the members stream for the shells on it and on the bump stream for the rest" do
    GridUplinkPresence.touch!(create(:grid_hackr), channel)
    GridUplinkPresence.touch!(create(:grid_hackr, :operator), channel)
    GridUplinkPresence.touch!(create(:grid_hackr, service_account: true), channel)
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)

    described_class.perform_now(channel.id)

    count = '<span id="uplink-count-ambient" class="uplink-channel-count" title="2 operatives connected">2</span>'
    expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).with(["uplink_members", "ambient"], target: "uplink-count-ambient", html: count)
    expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).with([Uplink::Unread::STREAM, "ambient"], target: "uplink-count-ambient", html: count)
    expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).exactly(3).times
  end

  it "hides the count at zero" do
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)

    described_class.perform_now(channel.id)

    expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).with(
      ["uplink_members", "ambient"], target: "uplink-count-ambient",
      html: '<span id="uplink-count-ambient" class="uplink-channel-count" hidden="hidden" title="0 operatives connected"></span>'
    )
  end

  it "releases the debounce claim so the next change schedules again, and skips missing channels" do
    allow(Uplink::MembersBroadcaster).to receive(:release).and_call_original
    allow(Uplink::MembersBroadcaster).to receive(:broadcast)

    described_class.perform_now(0)

    expect(Uplink::MembersBroadcaster).to have_received(:release).with(0)
    expect(Uplink::MembersBroadcaster).not_to have_received(:broadcast)
  end
end
