require "rails_helper"

RSpec.describe ChatMessage, type: :model do
  describe "validations" do
    it { should validate_presence_of(:content) }
    it { should validate_length_of(:content).is_at_most(512) }

    it "validates content cannot exceed 512 characters" do
      message = build(:chat_message, content: "a" * 513)
      expect(message).not_to be_valid
      expect(message.errors[:content]).to include("is too long (maximum is 512 characters)")
    end

    it "allows content up to 512 characters" do
      message = build(:chat_message, content: "a" * 512)
      expect(message).to be_valid
    end

    describe "profanity filtering" do
      it "allows clean content" do
        message = build(:chat_message, content: "Hello everyone!")
        expect(message).to be_valid
      end

      it "rejects content with profanity" do
        message = build(:chat_message, content: "This is some shit content")
        expect(message).not_to be_valid
        expect(message.errors[:content].first).to start_with("GOVCORP CENSOR:")
      end
    end
  end

  describe "associations" do
    it { should belong_to(:chat_channel) }
    it { should belong_to(:grid_hackr) }
    it { should belong_to(:hackr_stream).optional }
  end

  describe "scopes" do
    describe ".active" do
      it "returns only non-dropped messages" do
        active = create(:chat_message)
        create(:chat_message, :dropped)

        expect(ChatMessage.active).to contain_exactly(active)
      end
    end

    describe ".dropped" do
      it "returns only dropped messages" do
        create(:chat_message)
        dropped = create(:chat_message, :dropped)

        expect(ChatMessage.dropped).to contain_exactly(dropped)
      end
    end

    describe ".recent" do
      it "orders messages by created_at descending" do
        old = create(:chat_message, created_at: 2.hours.ago)
        new = create(:chat_message, created_at: 1.hour.ago)
        newest = create(:chat_message, created_at: 30.minutes.ago)

        expect(ChatMessage.recent.to_a).to eq([newest, new, old])
      end
    end
  end

  describe "callbacks" do
    describe "#broadcast_new_packet" do
      it "broadcasts to channel stream after create" do
        channel = create(:chat_channel, slug: "ambient")
        hackr = create(:grid_hackr)

        expect(ActionCable.server).to receive(:broadcast).with(
          "uplink:ambient",
          hash_including(
            type: "new_packet",
            packet: hash_including(
              content: "Test broadcast message",
              grid_hackr: hash_including(
                id: hackr.id,
                hackr_alias: hackr.hackr_alias
              )
            )
          )
        )

        create(:chat_message, chat_channel: channel, grid_hackr: hackr, content: "Test broadcast message")
      end
    end
  end

  describe "#drop!" do
    it "marks message as dropped and sets timestamp" do
      message = create(:chat_message)
      expect(message.dropped).to be false

      message.drop!
      message.reload

      expect(message.dropped).to be true
      expect(message.dropped_at).to be_within(1.second).of(Time.current)
    end

    it "broadcasts packet_dropped message" do
      message = create(:chat_message)

      expect(ActionCable.server).to receive(:broadcast).with(
        message.chat_channel.stream_name,
        hash_including(type: "packet_dropped", packet_id: message.id)
      )

      message.drop!
    end
  end

  describe "#restore!" do
    it "unmarks dropped and clears timestamp" do
      message = create(:chat_message, :dropped)
      expect(message.dropped).to be true

      message.restore!
      message.reload

      expect(message.dropped).to be false
      expect(message.dropped_at).to be_nil
    end

    it "broadcasts packet_restored message" do
      message = create(:chat_message, :dropped)

      expect(ActionCable.server).to receive(:broadcast).with(
        message.chat_channel.stream_name,
        hash_including(type: "packet_restored", packet_id: message.id)
      )

      message.restore!
    end
  end
end
