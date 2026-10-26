require "rails_helper"

# Uplink reactions (Phase 2 item 7): the row, the grouping the chips
# render from, the chip-row broadcast, and the emote/packet cascades.
RSpec.describe ChatMessageReaction, type: :model do
  let(:channel) { create(:chat_channel, slug: "ambient") }
  let(:packet) { create(:chat_message, chat_channel: channel, content: "react to me") }
  let(:hackr) { create(:grid_hackr) }
  let(:other) { create(:grid_hackr) }

  it "is one hackr, one emote, one packet, and the slug is emote-shaped" do
    create(:chat_message_reaction, chat_message: packet, grid_hackr: hackr, emote_slug: "wave")

    dup = build(:chat_message_reaction, chat_message: packet, grid_hackr: hackr, emote_slug: "wave")
    expect(dup).not_to be_valid
    expect(dup.errors[:grid_hackr_id]).to be_present
    expect(build(:chat_message_reaction, chat_message: packet, grid_hackr: hackr, emote_slug: "gg")).to be_valid
    expect(build(:chat_message_reaction, chat_message: packet, grid_hackr: other, emote_slug: "wave")).to be_valid
    expect(build(:chat_message_reaction, chat_message: packet, grid_hackr: other, emote_slug: "Wave!")).not_to be_valid
    expect(build(:chat_message_reaction, chat_message: packet, grid_hackr: other, emote_slug: "")).not_to be_valid
    expect(build(:chat_message_reaction, chat_message: packet, grid_hackr: other, emote_slug: "a" * 33)).not_to be_valid
    expect(ChatMessage::REACTION_CAP).to eq(20)
  end

  it "groups a packet's reactions by emote in first-reaction order, reactors as callsign tokens" do
    create(:chat_message_reaction, chat_message: packet, grid_hackr: hackr, emote_slug: "gg")
    create(:chat_message_reaction, chat_message: packet, grid_hackr: other, emote_slug: "wave")
    create(:chat_message_reaction, chat_message: packet, grid_hackr: hackr, emote_slug: "wave")

    expect(packet.reload.reaction_groups).to eq([
      ["gg", [Uplink::Callsign.token(hackr.id)]],
      ["wave", [Uplink::Callsign.token(other.id), Uplink::Callsign.token(hackr.id)]]
    ])
    expect(create(:chat_message, chat_channel: channel, content: "plain").reaction_groups).to eq([])
  end

  it "re-broadcasts the packet's chip row — never the packet row — on create and on destroy" do
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to).and_call_original
    chips = {target: "reactions_chat_message_#{packet.id}", partial: "uplink/reactions", locals: {packet: packet}}

    reaction = create(:chat_message_reaction, chat_message: packet, grid_hackr: hackr, emote_slug: "wave")
    expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).with(["uplink_html", "ambient"], chips).once

    reaction.destroy
    expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).with(["uplink_html", "ambient"], chips).twice
    expect(Turbo::StreamsChannel).not_to have_received(:broadcast_replace_to)
      .with(["uplink_html", "ambient"], hash_including(target: "chat_message_#{packet.id}"))
  end

  it "follows an emote rename, goes with a destroyed emote, and cascades from its packet and its hackr" do
    wave = create(:emote, slug: "wave")
    renamed = create(:chat_message_reaction, chat_message: packet, grid_hackr: hackr, emote_slug: "wave")
    kept = create(:chat_message_reaction, chat_message: packet, grid_hackr: other, emote_slug: "gg")

    wave.update!(slug: "wave2")
    expect(renamed.reload.emote_slug).to eq("wave2")
    expect(kept.reload.emote_slug).to eq("gg")

    wave.destroy
    expect(ChatMessageReaction.exists?(renamed.id)).to be(false)
    expect(ChatMessageReaction.exists?(kept.id)).to be(true)

    ChatMessage.where(id: packet.id).delete_all # the FK cascades at the database
    expect(ChatMessageReaction.exists?(kept.id)).to be(false)

    gone = create(:chat_message_reaction, chat_message: create(:chat_message, chat_channel: channel), grid_hackr: other, emote_slug: "gg")
    GridHackr.where(id: other.id).delete_all
    expect(ChatMessageReaction.exists?(gone.id)).to be(false)
  end
end
