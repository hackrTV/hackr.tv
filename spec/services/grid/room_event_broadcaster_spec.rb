require "rails_helper"

# Phase 6a dual-publish: room events keep their JSON GridChannel payloads
# (React tactical page until 6b) and additionally broadcast rendered
# terminal lines to per-room grid_room_html Turbo streams.
RSpec.describe Grid::RoomEventBroadcaster do
  let(:zone) { create(:grid_zone) }
  let(:room_a) { create(:grid_room, grid_zone: zone, name: "Alpha") }
  let(:room_b) { create(:grid_room, grid_zone: zone, name: "Beta") }
  let(:hackr) { create(:grid_hackr, current_room: room_b) }

  describe "movement" do
    let(:event) do
      {type: "movement", hackr_alias: hackr.hackr_alias, direction: "north",
       from_room_id: room_a.id, to_room_id: room_b.id}
    end

    it "dual-publishes per-room perspectives (departure old room, arrival new room)" do
      allow(GridChannel).to receive(:broadcast_to).and_call_original
      allow(Turbo::StreamsChannel).to receive(:broadcast_append_to).and_call_original

      described_class.publish(event, hackr: hackr)

      expect(GridChannel).to have_received(:broadcast_to).with(room_a, event)
      expect(GridChannel).to have_received(:broadcast_to).with(room_b, event)
      expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to).with(
        ["grid_room_html", room_a.id],
        hash_including(target: "grid-log", partial: "grid/event_line",
          locals: hash_including(text: "#{hackr.hackr_alias} leaves to the north."))
      )
      expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to).with(
        ["grid_room_html", room_b.id],
        hash_including(target: "grid-log", partial: "grid/event_line",
          locals: hash_including(text: "#{hackr.hackr_alias} enters from the south."))
      )
    end

    it "broadcasts zone presence JSON (tactical map)" do
      allow(ActionCable.server).to receive(:broadcast).and_call_original

      described_class.publish(event, hackr: hackr)

      expect(ActionCable.server).to have_received(:broadcast).with(
        ZoneChannel.stream_name_for(zone.id),
        hash_including(type: "presence_update", hackr_alias: hackr.hackr_alias)
      )
    end
  end

  describe "say" do
    it "dual-publishes the chat line to the current room" do
      event = {type: "say", hackr_alias: hackr.hackr_alias, message: "hello grid", room_id: room_b.id}
      allow(GridChannel).to receive(:broadcast_to).and_call_original
      allow(Turbo::StreamsChannel).to receive(:broadcast_append_to).and_call_original

      described_class.publish(event, hackr: hackr)

      expect(GridChannel).to have_received(:broadcast_to).with(room_b, event)
      expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to).with(
        ["grid_room_html", room_b.id],
        hash_including(partial: "grid/say_line",
          locals: {hackr_alias: hackr.hackr_alias, message: "hello grid"})
      )
    end
  end

  describe "take/drop" do
    it "dual-publishes the amber item line" do
      event = {type: "take", hackr_alias: hackr.hackr_alias, item_name: "scrap coil", room_id: room_b.id}
      allow(Turbo::StreamsChannel).to receive(:broadcast_append_to).and_call_original

      described_class.publish(event, hackr: hackr)

      expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to).with(
        ["grid_room_html", room_b.id],
        hash_including(partial: "grid/event_line",
          locals: hash_including(text: "#{hackr.hackr_alias} takes the scrap coil.", color: "#fbbf24"))
      )
    end
  end

  describe ".publish_system_broadcast" do
    it "dual-publishes the red bold system line" do
      event = {type: "system_broadcast", message: "[SYSTEM BROADCAST] maintenance", sender: "root"}
      allow(GridChannel).to receive(:broadcast_to).and_call_original
      allow(Turbo::StreamsChannel).to receive(:broadcast_append_to).and_call_original

      described_class.publish_system_broadcast(room_a, event)

      expect(GridChannel).to have_received(:broadcast_to).with(room_a, event)
      expect(Turbo::StreamsChannel).to have_received(:broadcast_append_to).with(
        ["grid_room_html", room_a.id],
        hash_including(partial: "grid/event_line",
          locals: hash_including(text: "[SYSTEM BROADCAST] maintenance", bold: true, color: "#f87171"))
      )
    end
  end
end
