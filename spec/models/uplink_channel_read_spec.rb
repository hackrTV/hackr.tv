require "rails_helper"

# == Schema Information
#
# Table name: uplink_channel_reads
# Database name: primary
#
#  id                   :integer          not null, primary key
#  read_at              :datetime         not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  chat_channel_id      :integer          not null
#  grid_hackr_id        :integer          not null
#  last_read_message_id :integer          default(0), not null
#
# Indexes
#
#  index_uplink_channel_reads_on_chat_channel_id  (chat_channel_id)
#  index_uplink_channel_reads_on_grid_hackr_id    (grid_hackr_id)
#  index_uplink_channel_reads_unique              (grid_hackr_id,chat_channel_id) UNIQUE
#
# Foreign Keys
#
#  chat_channel_id  (chat_channel_id => chat_channels.id)
#  grid_hackr_id    (grid_hackr_id => grid_hackrs.id)
#
RSpec.describe UplinkChannelRead do
  let(:hackr) { create(:grid_hackr) }
  let(:channel) { create(:chat_channel) }

  describe ".mark!" do
    it "creates the row at the given packet id" do
      expect { described_class.mark!(hackr, channel, 42) }.to change(described_class, :count).by(1)

      row = described_class.find_by!(grid_hackr: hackr, chat_channel: channel)
      expect(row.last_read_message_id).to eq(42)
      expect(row.read_at).to be_within(2.seconds).of(Time.current)
    end

    it "raises the mark and never lowers it (a late ack from a tab that fell behind is a no-op)" do
      described_class.mark!(hackr, channel, 42)
      described_class.mark!(hackr, channel, 50)
      expect(described_class.find_by!(grid_hackr: hackr, chat_channel: channel).last_read_message_id).to eq(50)

      expect { described_class.mark!(hackr, channel, 10) }.not_to change { described_class.find_by!(grid_hackr: hackr, chat_channel: channel).reload.updated_at }
      expect(described_class.find_by!(grid_hackr: hackr, chat_channel: channel).last_read_message_id).to eq(50)
      expect(described_class.count).to eq(1)
    end

    it "takes the update path when a concurrent first mark won the unique index" do
      # The race: our lookup found nothing, the other tab inserted between
      # our validation and our INSERT, so save! raises from the index (the
      # uniqueness validation can't see a row that isn't there yet).
      stale = described_class.new(grid_hackr: hackr, chat_channel: channel)
      allow(stale).to receive(:save!).and_raise(ActiveRecord::RecordNotUnique.new("UNIQUE constraint failed"))
      calls = 0
      allow(described_class).to receive(:find_or_initialize_by).and_wrap_original do |m, *args, **kwargs|
        calls += 1
        if calls == 1
          described_class.create!(grid_hackr: hackr, chat_channel: channel, last_read_message_id: 5) # the other tab wins
          stale
        else
          m.call(*args, **kwargs)
        end
      end

      row = described_class.mark!(hackr, channel, 9)

      expect(row.last_read_message_id).to eq(9)
      expect(described_class.count).to eq(1)
    end
  end

  describe ".seed!" do
    let(:other) { create(:chat_channel) }

    it "inserts a caught-up row per channel id and leaves existing rows alone" do
      described_class.mark!(hackr, channel, 7)

      inserted = described_class.seed!(hackr, {channel.id => 99, other.id => 3})

      expect(inserted).to eq(1)
      expect(described_class.find_by!(grid_hackr: hackr, chat_channel: channel).last_read_message_id).to eq(7)
      expect(described_class.find_by!(grid_hackr: hackr, chat_channel: other).last_read_message_id).to eq(3)
    end

    it "is a no-op for an empty hash" do
      expect(described_class.seed!(hackr, {})).to eq(0)
    end
  end

  it "enforces one row per hackr and channel" do
    described_class.create!(grid_hackr: hackr, chat_channel: channel, read_at: Time.current)
    dup = described_class.new(grid_hackr: hackr, chat_channel: channel, read_at: Time.current)
    expect(dup).not_to be_valid
  end
end
