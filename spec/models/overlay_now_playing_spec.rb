# == Schema Information
#
# Table name: overlay_now_playing
# Database name: primary
#
#  id            :integer          not null, primary key
#  custom_artist :string
#  custom_title  :string
#  is_live       :boolean          default(FALSE)
#  paused        :boolean          default(FALSE), not null
#  started_at    :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  track_id      :integer
#
# Indexes
#
#  index_overlay_now_playing_on_track_id  (track_id)
#
# Foreign Keys
#
#  track_id  (track_id => tracks.id)
#
require "rails_helper"

RSpec.describe OverlayNowPlaying, type: :model do
  describe "associations" do
    it { should belong_to(:track).optional }
  end

  describe ".current" do
    it "returns existing record if present" do
      existing = OverlayNowPlaying.create!
      expect(OverlayNowPlaying.current).to eq(existing)
    end

    it "creates a record if none exists" do
      expect { OverlayNowPlaying.current }.to change(OverlayNowPlaying, :count).by(1)
    end

    it "always returns the same record" do
      first = OverlayNowPlaying.current
      second = OverlayNowPlaying.current
      expect(first).to eq(second)
    end
  end

  describe ".set_track!" do
    let(:artist) { create(:artist) }
    let(:track) { create(:track, artist: artist) }

    before do
      allow(ActionCable.server).to receive(:broadcast)
    end

    it "sets the track" do
      OverlayNowPlaying.set_track!(track)
      expect(OverlayNowPlaying.current.track).to eq(track)
    end

    it "clears custom title and artist" do
      OverlayNowPlaying.current.update!(custom_title: "Custom", custom_artist: "Artist")
      OverlayNowPlaying.set_track!(track)
      expect(OverlayNowPlaying.current.custom_title).to be_nil
      expect(OverlayNowPlaying.current.custom_artist).to be_nil
    end

    it "sets started_at" do
      before = Time.current
      OverlayNowPlaying.set_track!(track)
      after = Time.current

      expect(OverlayNowPlaying.current.started_at).to be >= before
      expect(OverlayNowPlaying.current.started_at).to be <= after
    end

    it "sets paused state" do
      OverlayNowPlaying.set_track!(track, paused: true)
      expect(OverlayNowPlaying.current.paused).to be true
    end

    it "broadcasts change" do
      expect(ActionCable.server).to receive(:broadcast).with("overlay_updates", hash_including(type: "now_playing_changed"))
      OverlayNowPlaying.set_track!(track)
    end
  end

  describe ".set_custom!" do
    before do
      allow(ActionCable.server).to receive(:broadcast)
    end

    it "sets custom title and artist" do
      OverlayNowPlaying.set_custom!(title: "Custom Song", artist: "Custom Artist")
      expect(OverlayNowPlaying.current.custom_title).to eq("Custom Song")
      expect(OverlayNowPlaying.current.custom_artist).to eq("Custom Artist")
    end

    it "clears track" do
      artist = create(:artist)
      track = create(:track, artist: artist)
      OverlayNowPlaying.current.update!(track: track)
      OverlayNowPlaying.set_custom!(title: "Custom")
      expect(OverlayNowPlaying.current.track).to be_nil
    end

    it "broadcasts change" do
      expect(ActionCable.server).to receive(:broadcast).with("overlay_updates", hash_including(type: "now_playing_changed"))
      OverlayNowPlaying.set_custom!(title: "Custom")
    end
  end

  describe ".set_paused!" do
    before do
      allow(ActionCable.server).to receive(:broadcast)
    end

    it "updates paused state" do
      OverlayNowPlaying.set_paused!(true)
      expect(OverlayNowPlaying.current.paused).to be true

      OverlayNowPlaying.set_paused!(false)
      expect(OverlayNowPlaying.current.paused).to be false
    end

    it "broadcasts change" do
      expect(ActionCable.server).to receive(:broadcast).with("overlay_updates", hash_including(type: "now_playing_changed"))
      OverlayNowPlaying.set_paused!(true)
    end
  end

  describe ".clear!" do
    before do
      allow(ActionCable.server).to receive(:broadcast)
    end

    it "clears all now playing data" do
      artist = create(:artist)
      track = create(:track, artist: artist)
      OverlayNowPlaying.current.update!(
        track: track,
        custom_title: "Custom",
        custom_artist: "Artist",
        started_at: Time.current,
        paused: true
      )

      OverlayNowPlaying.clear!
      now_playing = OverlayNowPlaying.current

      expect(now_playing.track).to be_nil
      expect(now_playing.custom_title).to be_nil
      expect(now_playing.custom_artist).to be_nil
      expect(now_playing.started_at).to be_nil
      expect(now_playing.paused).to be false
    end

    it "broadcasts change" do
      expect(ActionCable.server).to receive(:broadcast).with("overlay_updates", hash_including(type: "now_playing_changed"))
      OverlayNowPlaying.clear!
    end
  end

  describe "#display_title" do
    it "returns custom title when present" do
      now_playing = build(:overlay_now_playing, custom_title: "Custom")
      expect(now_playing.display_title).to eq("Custom")
    end

    it "returns track title when no custom title" do
      artist = create(:artist)
      track = create(:track, title: "Track Title", artist: artist)
      now_playing = build(:overlay_now_playing, track: track)
      expect(now_playing.display_title).to eq("Track Title")
    end

    it "returns default when nothing playing" do
      now_playing = build(:overlay_now_playing)
      expect(now_playing.display_title).to eq("Nothing Playing")
    end
  end

  describe "#display_artist" do
    it "returns custom artist when present" do
      now_playing = build(:overlay_now_playing, custom_artist: "Custom Artist")
      expect(now_playing.display_artist).to eq("Custom Artist")
    end

    it "returns track artist when no custom artist" do
      artist = create(:artist, name: "Artist Name")
      track = create(:track, artist: artist)
      now_playing = build(:overlay_now_playing, track: track)
      expect(now_playing.display_artist).to eq("Artist Name")
    end

    it "returns empty string when nothing playing" do
      now_playing = build(:overlay_now_playing)
      expect(now_playing.display_artist).to eq("")
    end
  end

  describe "#display_album" do
    it "returns release name when track has release" do
      artist = create(:artist)
      release = create(:release, name: "Release Name", artist: artist)
      track = create(:track, artist: artist, release: release)
      now_playing = build(:overlay_now_playing, track: track)
      expect(now_playing.display_album).to eq("Release Name")
    end

    it "returns empty string when no release" do
      now_playing = build(:overlay_now_playing)
      expect(now_playing.display_album).to eq("")
    end
  end

  describe "#playing?" do
    it "returns true when track is present" do
      artist = create(:artist)
      track = create(:track, artist: artist)
      now_playing = build(:overlay_now_playing, track: track)
      expect(now_playing.playing?).to be true
    end

    it "returns true when custom title is present" do
      now_playing = build(:overlay_now_playing, custom_title: "Custom")
      expect(now_playing.playing?).to be true
    end

    it "returns false when nothing playing" do
      now_playing = build(:overlay_now_playing)
      expect(now_playing.playing?).to be false
    end
  end
end
