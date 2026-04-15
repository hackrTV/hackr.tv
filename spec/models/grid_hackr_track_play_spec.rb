# == Schema Information
#
# Table name: grid_hackr_track_plays
# Database name: primary
#
#  id              :integer          not null, primary key
#  first_played_at :datetime         not null
#  play_count      :integer          default(1), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  grid_hackr_id   :integer          not null
#  track_id        :integer          not null
#
# Indexes
#
#  index_grid_hackr_track_plays_on_grid_hackr_id  (grid_hackr_id)
#  index_grid_hackr_track_plays_on_track_id       (track_id)
#  index_track_plays_unique                       (grid_hackr_id,track_id) UNIQUE
#
# Foreign Keys
#
#  grid_hackr_id  (grid_hackr_id => grid_hackrs.id)
#  track_id       (track_id => tracks.id)
#
require "rails_helper"

RSpec.describe GridHackrTrackPlay do
  let(:hackr) { create(:grid_hackr) }
  let(:track) { create(:track) }

  describe ".record!" do
    it "creates a new row with play_count=1 on first call" do
      record = described_class.record!(hackr, track)
      expect(record.play_count).to eq(1)
      expect(record.first_played_at).to be_within(1.second).of(Time.current)
    end

    it "increments play_count on subsequent calls" do
      described_class.record!(hackr, track)
      record = described_class.record!(hackr, track)
      expect(record.play_count).to eq(2)
    end

    it "does not create a duplicate for the same hackr+track" do
      described_class.record!(hackr, track)
      expect {
        described_class.record!(hackr, track)
      }.not_to change { described_class.count }
    end

    it "creates separate rows for different tracks" do
      other = create(:track)
      described_class.record!(hackr, track)
      described_class.record!(hackr, other)
      expect(described_class.count).to eq(2)
    end
  end
end
