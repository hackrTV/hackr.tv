# == Schema Information
#
# Table name: hackr_streams
# Database name: primary
#
#  id           :integer          not null, primary key
#  cancelled_at :datetime
#  ended_at     :datetime
#  is_live      :boolean          default(FALSE), not null
#  live_url     :string
#  scheduled_at :datetime
#  started_at   :datetime
#  title        :string
#  track_slug   :string
#  vod_url      :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  artist_id    :integer          not null
#
# Indexes
#
#  index_hackr_streams_on_artist_id     (artist_id)
#  index_hackr_streams_on_scheduled_at  (scheduled_at)
#
# Foreign Keys
#
#  artist_id  (artist_id => artists.id)
#
require "rails_helper"

RSpec.describe HackrStream, type: :model do
  describe ".upcoming" do
    it "returns scheduled, non-cancelled, non-ended, non-live streams ordered by scheduled_at" do
      artist = create(:artist)
      later = create(:hackr_stream, :scheduled, artist: artist, scheduled_at: 3.hours.from_now)
      sooner = create(:hackr_stream, :scheduled, artist: artist, scheduled_at: 1.hour.from_now)

      expect(described_class.upcoming).to eq([sooner, later])
    end

    it "excludes cancelled streams" do
      create(:hackr_stream, :cancelled)
      expect(described_class.upcoming).to be_empty
    end

    it "excludes live streams" do
      create(:hackr_stream, :live, scheduled_at: 1.hour.from_now)
      expect(described_class.upcoming).to be_empty
    end

    it "excludes ended streams" do
      create(:hackr_stream, :scheduled, ended_at: 1.hour.ago)
      expect(described_class.upcoming).to be_empty
    end

    it "excludes expired streams (>1hr past scheduled_at)" do
      create(:hackr_stream, :expired_schedule)
      expect(described_class.upcoming).to be_empty
    end

    it "includes starting-soon streams (past scheduled_at within 1hr)" do
      stream = create(:hackr_stream, :starting_soon)
      expect(described_class.upcoming).to eq([stream])
    end

    it "excludes streams with no scheduled_at" do
      create(:hackr_stream)
      expect(described_class.upcoming).to be_empty
    end
  end

  describe ".past_broadcasts" do
    it "returns streams with started_at that are not live, ordered by started_at desc" do
      artist = create(:artist)
      older = create(:hackr_stream, artist: artist, started_at: 2.days.ago, ended_at: 2.days.ago + 1.hour)
      newer = create(:hackr_stream, artist: artist, started_at: 1.day.ago, ended_at: 1.day.ago + 1.hour)

      expect(described_class.past_broadcasts).to eq([newer, older])
    end

    it "excludes live streams" do
      create(:hackr_stream, :live)
      expect(described_class.past_broadcasts).to be_empty
    end

    it "excludes streams with no started_at" do
      create(:hackr_stream, :scheduled)
      expect(described_class.past_broadcasts).to be_empty
    end
  end

  describe ".next_scheduled" do
    it "returns the soonest upcoming stream" do
      artist = create(:artist)
      create(:hackr_stream, :scheduled, artist: artist, scheduled_at: 3.hours.from_now)
      sooner = create(:hackr_stream, :scheduled, artist: artist, scheduled_at: 1.hour.from_now)

      expect(described_class.next_scheduled).to eq(sooner)
    end

    it "returns nil when no upcoming streams" do
      expect(described_class.next_scheduled).to be_nil
    end

    it "skips cancelled streams and returns next non-cancelled" do
      artist = create(:artist)
      create(:hackr_stream, :cancelled, artist: artist, scheduled_at: 1.hour.from_now)
      next_stream = create(:hackr_stream, :scheduled, artist: artist, scheduled_at: 2.hours.from_now)

      expect(described_class.next_scheduled).to eq(next_stream)
    end
  end

  describe "#display_state" do
    it "returns :live when stream is live" do
      stream = build(:hackr_stream, :live)
      expect(stream.display_state).to eq(:live)
    end

    it "returns :cancelled when cancelled_at is set" do
      stream = build(:hackr_stream, :cancelled)
      expect(stream.display_state).to eq(:cancelled)
    end

    it "returns :ended when ended_at is set" do
      stream = build(:hackr_stream, ended_at: 1.hour.ago)
      expect(stream.display_state).to eq(:ended)
    end

    it "returns :expired when scheduled_at is >1hr past and never went live" do
      stream = build(:hackr_stream, :expired_schedule)
      expect(stream.display_state).to eq(:expired)
    end

    it "returns :starting_soon when scheduled_at is past but within 1hr" do
      stream = build(:hackr_stream, :starting_soon)
      expect(stream.display_state).to eq(:starting_soon)
    end

    it "returns :upcoming when scheduled_at is in future" do
      stream = build(:hackr_stream, :scheduled)
      expect(stream.display_state).to eq(:upcoming)
    end

    it "returns :unscheduled when no scheduled_at" do
      stream = build(:hackr_stream, started_at: nil)
      expect(stream.display_state).to eq(:unscheduled)
    end

    it "prioritizes :live over :cancelled" do
      stream = build(:hackr_stream, :live, cancelled_at: 1.hour.ago)
      expect(stream.display_state).to eq(:live)
    end

    it "prioritizes :cancelled over :expired" do
      stream = build(:hackr_stream, scheduled_at: 2.hours.ago, cancelled_at: 1.hour.ago, started_at: nil, ended_at: nil)
      expect(stream.display_state).to eq(:cancelled)
    end
  end

  describe "#starting_soon?" do
    it "returns true when scheduled_at is past but within expiry window" do
      stream = build(:hackr_stream, :starting_soon)
      expect(stream.starting_soon?).to be true
    end

    it "returns false when scheduled_at is in the future" do
      stream = build(:hackr_stream, :scheduled)
      expect(stream.starting_soon?).to be false
    end

    it "returns false when expired (>1hr past)" do
      stream = build(:hackr_stream, :expired_schedule)
      expect(stream.starting_soon?).to be false
    end

    it "returns false when live" do
      stream = build(:hackr_stream, :live, scheduled_at: 10.minutes.ago)
      expect(stream.starting_soon?).to be false
    end

    it "returns false when cancelled" do
      stream = build(:hackr_stream, :starting_soon, cancelled_at: 5.minutes.ago)
      expect(stream.starting_soon?).to be false
    end
  end

  describe "#expired?" do
    it "returns true when scheduled_at is >1hr past and never went live" do
      stream = build(:hackr_stream, :expired_schedule)
      expect(stream.expired?).to be true
    end

    it "returns false when within expiry window" do
      stream = build(:hackr_stream, :starting_soon)
      expect(stream.expired?).to be false
    end

    it "returns false when ended (went live then ended)" do
      stream = build(:hackr_stream, scheduled_at: 2.hours.ago, started_at: 2.hours.ago, ended_at: 1.hour.ago)
      expect(stream.expired?).to be false
    end

    it "returns false when cancelled" do
      stream = build(:hackr_stream, scheduled_at: 2.hours.ago, cancelled_at: 1.hour.ago, started_at: nil, ended_at: nil)
      expect(stream.expired?).to be false
    end
  end

  describe "#cancel!" do
    it "sets cancelled_at" do
      stream = create(:hackr_stream, :scheduled)
      stream.cancel!
      expect(stream.reload.cancelled_at).to be_present
    end

    it "raises error when stream is live" do
      stream = create(:hackr_stream, :live)
      expect { stream.cancel! }.to raise_error(ActiveRecord::RecordInvalid, /Cannot cancel a live stream/)
    end

    it "does not modify is_live" do
      stream = create(:hackr_stream, :scheduled)
      stream.cancel!
      expect(stream.reload.is_live).to be false
    end
  end

  describe "#go_live!" do
    it "sets is_live, live_url, started_at" do
      stream = create(:hackr_stream, :scheduled)
      stream.go_live!("https://www.youtube.com/embed/abc123", "Live Title")
      stream.reload
      expect(stream.is_live).to be true
      expect(stream.live_url).to eq("https://www.youtube.com/embed/abc123")
      expect(stream.title).to eq("Live Title")
      expect(stream.started_at).to be_present
    end

    it "preserves existing title when no title given" do
      stream = create(:hackr_stream, :scheduled, title: "Original Title")
      stream.go_live!("https://www.youtube.com/embed/abc123")
      expect(stream.reload.title).to eq("Original Title")
    end

    it "works on a scheduled stream that has never been live" do
      stream = create(:hackr_stream, :scheduled)
      expect { stream.go_live!(stream.live_url, stream.title) }.not_to raise_error
      expect(stream.reload.is_live).to be true
    end

    it "rejects going live on an ended stream" do
      stream = create(:hackr_stream, started_at: 2.hours.ago, ended_at: 1.hour.ago)
      expect {
        stream.go_live!("https://www.youtube.com/embed/abc123")
      }.to raise_error(ActiveRecord::RecordInvalid, /Cannot restart/)
    end
  end

  describe "#stream_json" do
    it "returns hash with id, title, artist name, started_at" do
      stream = create(:hackr_stream, :live)
      json = stream.stream_json
      expect(json[:id]).to eq(stream.id)
      expect(json[:title]).to eq(stream.title)
      expect(json[:artist]).to eq(stream.artist.name)
      expect(json[:started_at]).to eq(stream.started_at.iso8601)
    end
  end

  describe "#scheduled_json" do
    it "returns hash with id, title, artist name, artist_slug, scheduled_at, display_state" do
      stream = create(:hackr_stream, :scheduled)
      json = stream.scheduled_json
      expect(json[:id]).to eq(stream.id)
      expect(json[:title]).to eq(stream.title)
      expect(json[:artist]).to eq(stream.artist.name)
      expect(json[:artist_slug]).to eq(stream.artist.slug)
      expect(json[:scheduled_at]).to eq(stream.scheduled_at.iso8601)
      expect(json[:display_state]).to eq("upcoming")
    end

    it "reflects starting_soon display_state" do
      stream = build(:hackr_stream, :starting_soon)
      expect(stream.scheduled_json[:display_state]).to eq("starting_soon")
    end
  end

  describe "broadcast on schedule changes" do
    it "broadcasts when scheduled_at changes" do
      stream = create(:hackr_stream, :scheduled)
      expect {
        stream.update!(scheduled_at: 5.hours.from_now)
      }.to have_broadcasted_to("stream_status")
    end

    it "broadcasts when cancelled_at changes" do
      stream = create(:hackr_stream, :scheduled)
      expect {
        stream.cancel!
      }.to have_broadcasted_to("stream_status")
    end

    it "does not broadcast when unrelated fields change" do
      stream = create(:hackr_stream, :scheduled)
      expect {
        stream.update!(title: "New Title")
      }.not_to have_broadcasted_to("stream_status")
    end
  end
end
