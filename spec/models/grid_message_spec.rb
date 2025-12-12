require "rails_helper"

RSpec.describe GridMessage, type: :model do
  describe "associations" do
    it { should belong_to(:grid_hackr) }
    it { should belong_to(:room).optional }
    it { should belong_to(:target_hackr).optional }
  end

  describe "validations" do
    it { should validate_presence_of(:content) }
    it { should validate_inclusion_of(:message_type).in_array(%w[say whisper broadcast system]) }

    describe "profanity filtering" do
      let(:hackr) { create(:grid_hackr) }
      let(:room) { create(:grid_room) }

      it "allows clean content" do
        message = build(:grid_message, grid_hackr: hackr, room: room, content: "Hello fellow hackrs")
        expect(message).to be_valid
      end

      it "rejects content with profanity" do
        message = build(:grid_message, grid_hackr: hackr, room: room, content: "This is some shit message")
        expect(message).not_to be_valid
        expect(message.errors[:content].first).to start_with("GOVCORP CENSOR:")
      end

      it "returns GovCorp themed rejection message" do
        message = build(:grid_message, grid_hackr: hackr, room: room, content: "What the fuck")
        message.valid?
        expect(message.errors[:content].first).to include("GOVCORP CENSOR")
      end
    end
  end

  describe "scopes" do
    describe ".recent" do
      it "returns messages ordered by created_at desc, limited to 50" do
        hackr = create(:grid_hackr)
        room = create(:grid_room)
        messages = create_list(:grid_message, 3, grid_hackr: hackr, room: room)

        expect(GridMessage.recent).to eq(messages.reverse)
      end
    end

    describe ".in_room" do
      it "returns only say messages for the specified room" do
        hackr = create(:grid_hackr)
        room1 = create(:grid_room)
        room2 = create(:grid_room)

        say_msg = create(:grid_message, grid_hackr: hackr, room: room1, message_type: "say")
        create(:grid_message, grid_hackr: hackr, room: room2, message_type: "say")
        create(:grid_message, grid_hackr: hackr, room: room1, message_type: "whisper")

        expect(GridMessage.in_room(room1)).to eq([say_msg])
      end
    end
  end
end
