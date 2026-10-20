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

  it "releases the debounce claim so the next change schedules again, and skips missing channels" do
    allow(Uplink::MembersBroadcaster).to receive(:release).and_call_original
    allow(Uplink::MembersBroadcaster).to receive(:broadcast)

    described_class.perform_now(0)

    expect(Uplink::MembersBroadcaster).to have_received(:release).with(0)
    expect(Uplink::MembersBroadcaster).not_to have_received(:broadcast)
  end
end
