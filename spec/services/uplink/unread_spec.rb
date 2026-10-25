require "rails_helper"

RSpec.describe Uplink::Unread do
  let(:viewer) { create(:grid_hackr, hackr_alias: "Node_Op") }
  let(:other) { create(:grid_hackr) }
  let(:ambient) { create(:chat_channel, slug: "ambient") }
  let(:trace) { create(:chat_channel, slug: "trace") }
  let(:ops) { create(:chat_channel, slug: "ops") }
  let(:channels) { [ambient, trace, ops] }

  def mark_for(channel)
    UplinkChannelRead.find_by!(grid_hackr: viewer, chat_channel: channel).last_read_message_id
  end

  it "seeds a caught-up mark for every channel on first sight (nothing counts) and marks the channel on screen at its newest packet" do
    old_trace = create(:chat_message, chat_channel: trace, grid_hackr: other)
    newest_ambient = create(:chat_message, chat_channel: ambient, grid_hackr: other)

    result = described_class.sync(viewer, channels, reading: ambient)

    expect(result.keys).to contain_exactly(trace.id, ops.id) # the channel on screen is never counted
    expect(result.values.map(&:count)).to eq([0, 0])
    expect(mark_for(ambient)).to eq(newest_ambient.id)
    expect(mark_for(trace)).to eq(old_trace.id)
    expect(mark_for(ops)).to eq(0) # no packets yet
  end

  it "counts active packets above the mark per channel, flags the ones that @mention the viewer, and moves the mark of the channel on screen" do
    described_class.sync(viewer, channels, reading: ambient)
    create(:chat_message, chat_channel: trace, grid_hackr: other, content: "hello")
    create(:chat_message, chat_channel: trace, grid_hackr: other, content: "ping @NODE_OP (case-insensitive)")
    create(:chat_message, :dropped, chat_channel: trace, grid_hackr: other, content: "dropped: not counted")
    create(:chat_message, chat_channel: ops, grid_hackr: viewer, content: "my own @node_op packet elsewhere: counted, not a mention")
    create(:chat_message, chat_channel: ambient, grid_hackr: other, content: "arrived while away")

    result = described_class.sync(viewer, channels, reading: ops)

    expect(result[trace.id]).to have_attributes(count: 2, mentioned: true, label: "2", any?: true)
    expect(result[ambient.id]).to have_attributes(count: 1, mentioned: false)
    expect(result).not_to have_key(ops.id)
    expect(mark_for(ops)).to eq(ChatMessage.where(chat_channel: ops).maximum(:id))
    expect(mark_for(trace)).to eq(0) # untouched: still unread next time
  end

  it "escapes LIKE wildcards in the alias and ignores look-alikes" do
    described_class.sync(viewer, channels, reading: ambient)
    create(:chat_message, chat_channel: trace, grid_hackr: other, content: "@nodexop is not me") # _ must not act as a wildcard

    expect(described_class.sync(viewer, channels, reading: ambient)[trace.id]).to have_attributes(count: 1, mentioned: false)
  end

  it "caps the label at 99+ and copes with no channels or no channel on screen" do
    expect(described_class.label(99)).to eq("99")
    expect(described_class.label(100)).to eq("99+")
    expect(described_class.sync(viewer, [], reading: nil)).to eq({})

    result = described_class.sync(viewer, [trace], reading: nil)
    expect(result.keys).to eq([trace.id])
    expect(mark_for(trace)).to eq(0)
  end
end
