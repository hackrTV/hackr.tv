require "rails_helper"

# == Schema Information
#
# Table name: grid_uplink_presences
# Database name: primary
#
#  id              :integer          not null, primary key
#  last_seen_at    :datetime         not null
#  chat_channel_id :integer          not null
#  grid_hackr_id   :integer          not null
#
# Indexes
#
#  index_grid_uplink_presences_on_last_seen_at  (last_seen_at)
#  index_grid_uplink_presences_unique           (grid_hackr_id,chat_channel_id) UNIQUE
#
RSpec.describe GridUplinkPresence, type: :model do
  include ActiveJob::TestHelper

  let(:channel) { create(:chat_channel) }
  let(:hackr) { create(:grid_hackr) }

  describe "roster broadcasts (Uplink shell operatives pane)" do
    it "schedules one on a new presence row" do
      expect { described_class.touch!(hackr, channel) }
        .to have_enqueued_job(Uplink::MembersBroadcastJob).with(channel.id)
    end

    it "stays quiet on the periodic touch of a live row" do
      described_class.touch!(hackr, channel)

      expect { described_class.touch!(hackr, channel) }
        .not_to have_enqueued_job(Uplink::MembersBroadcastJob)
    end

    it "schedules one when a stale row comes back" do
      row = described_class.touch!(hackr, channel)
      row.update_column(:last_seen_at, (Grid::EconomyConfig::PRESENCE_TTL + 1.minute).ago)

      expect { described_class.touch!(hackr, channel) }
        .to have_enqueued_job(Uplink::MembersBroadcastJob).with(channel.id)
    end

    it "schedules one on remove!" do
      described_class.touch!(hackr, channel)

      expect { expect(described_class.remove!(hackr, channel)).to eq(1) }
        .to have_enqueued_job(Uplink::MembersBroadcastJob).with(channel.id)
      expect(described_class.count).to eq(0)
    end

    it "schedules one per affected channel on cleanup_stale! so open shells drop the ghosts" do
      other_channel = create(:chat_channel)
      described_class.touch!(hackr, channel).update_column(:last_seen_at, (Grid::EconomyConfig::PRESENCE_TTL + 1.minute).ago)
      described_class.touch!(create(:grid_hackr), channel).update_column(:last_seen_at, (Grid::EconomyConfig::PRESENCE_TTL + 1.minute).ago)
      described_class.touch!(hackr, other_channel) # fresh: untouched

      expect { expect(described_class.cleanup_stale!).to eq(2) }
        .to have_enqueued_job(Uplink::MembersBroadcastJob).with(channel.id).once
      expect(described_class.count).to eq(1)
    end
  end
end
