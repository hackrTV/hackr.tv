require "rails_helper"

# Typing indicator state (Phase 2 item 8): per-channel composing aliases
# with a TTL, re-broadcast on every touch and on every effective stop.
RSpec.describe Uplink::Typing do
  include ActiveSupport::Testing::TimeHelpers

  let(:channel) { create(:chat_channel, slug: "ambient") }
  let(:hackr) { create(:grid_hackr) }
  let(:other) { create(:grid_hackr) }

  before { allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to) }
  after { described_class.reset! }

  def name(of)
    of.hackr_alias
  end

  def line(aliases)
    {target: "uplink-typing", partial: "uplink/typing", locals: {aliases: aliases}}
  end

  it "keeps an alias per composing hackr for TTL seconds past its last touch, in first-touch order, broadcasting the channel's list on every touch" do
    expect(described_class.aliases(channel)).to eq([])

    expect(described_class.touch(channel, hackr)).to eq([name(hackr)])
    expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).with(["uplink_typing", "ambient"], line([name(hackr)])).once

    travel 2.seconds
    expect(described_class.touch(channel, other)).to eq([name(hackr), name(other)])
    expect(described_class.touch(channel, hackr)).to eq([name(hackr), name(other)]) # a refresh keeps the order
    expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).with(["uplink_typing", "ambient"], line([name(hackr), name(other)])).twice

    travel 2.seconds
    expect(described_class.touch(channel, other)).to eq([name(hackr), name(other)])
    travel 2.seconds # hackr's last touch is 4s old, other's 2s
    expect(described_class.aliases(channel)).to eq([name(hackr), name(other)])
    travel 1.5.seconds # 5.5s and 3.5s: hackr has faded
    expect(described_class.aliases(channel)).to eq([name(other)])
    travel 2.seconds
    expect(described_class.aliases(channel)).to eq([])
    expect(described_class::TTL).to eq(5)
  end

  it "stops a hackr — broadcasting only when they were in the line — and keeps channels apart" do
    trace = create(:chat_channel, slug: "trace")
    described_class.touch(channel, hackr)
    described_class.touch(channel, other)
    described_class.touch(trace, hackr)

    expect(described_class.stop(channel, hackr)).to eq([name(other)])
    expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).with(["uplink_typing", "ambient"], line([name(other)])).once
    expect(described_class.aliases(trace)).to eq([name(hackr)])

    expect(described_class.stop(channel, hackr)).to eq([name(other)]) # nothing to drop: no broadcast
    expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).with(["uplink_typing", "ambient"], anything).exactly(3).times # two touches + one stop
    expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).with(["uplink_typing", "trace"], anything).once

    described_class.reset!
    expect(described_class.aliases(channel)).to eq([])
    expect(described_class.aliases(trace)).to eq([])
  end

  it "renders the line partial viewer-neutral: aliases + ttl for the client, no text" do
    html = ApplicationController.render(partial: "uplink/typing", locals: {aliases: %w[xeraen ghost_op]})

    expect(html).to match(%r{<div id="uplink-typing" class="uplink-typing" role="status" aria-live="polite" data-controller="typing"\s+data-typing-aliases-value="\[&quot;xeraen&quot;,&quot;ghost_op&quot;\]" data-typing-ttl-value="5000"></div>})
    expect(html).not_to include("transmitting")
  end
end
