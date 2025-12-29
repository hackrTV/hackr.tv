require "rails_helper"

RSpec.describe Track, type: :model do
  describe "associations" do
    it "belongs to an artist" do
      association = Track.reflect_on_association(:artist)
      expect(association.macro).to eq(:belongs_to)
    end

    it "belongs to an album" do
      association = Track.reflect_on_association(:album)
      expect(association.macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    let(:artist) { create(:artist) }

    it "is valid with valid attributes" do
      track = build(:track, artist: artist)
      expect(track).to be_valid
    end

    it "is invalid without a title" do
      track = build(:track, artist: artist, title: nil)
      expect(track).not_to be_valid
      expect(track.errors[:title]).to include("can't be blank")
    end

    it "is invalid without a slug" do
      track = build(:track, artist: artist, slug: nil)
      expect(track).not_to be_valid
      expect(track.errors[:slug]).to include("can't be blank")
    end

    it "is invalid without an artist" do
      track = build(:track, artist: nil)
      expect(track).not_to be_valid
    end

    it "is invalid without an album" do
      track = build(:track, album: nil)
      expect(track).not_to be_valid
    end

    it "requires unique slug scoped to artist" do
      create(:track, artist: artist, slug: "unique-track")
      duplicate = build(:track, artist: artist, slug: "unique-track")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:slug]).to include("has already been taken")
    end

    it "allows same slug for different artists" do
      artist1 = create(:artist, slug: "artist-1")
      artist2 = create(:artist, slug: "artist-2")
      create(:track, artist: artist1, slug: "same-slug")
      duplicate = build(:track, artist: artist2, slug: "same-slug")
      expect(duplicate).to be_valid
    end
  end

  describe "JSON serialization" do
    it "serializes streaming_links as JSON" do
      track = create(:track, streaming_links: {spotify: "url1", youtube: "url2"})
      track.reload
      expect(track.streaming_links).to eq({"spotify" => "url1", "youtube" => "url2"})
    end

    it "serializes videos as JSON" do
      track = create(:track, videos: {music: "url1", lyric: "url2"})
      track.reload
      expect(track.videos).to eq({"music" => "url1", "lyric" => "url2"})
    end

    it "handles nil streaming_links" do
      track = create(:track, streaming_links: nil)
      expect(track.streaming_links).to be_nil
    end

    it "handles nil videos" do
      track = create(:track, videos: nil)
      expect(track.videos).to be_nil
    end
  end

  describe "scopes" do
    let(:artist) { create(:artist) }

    describe ".featured" do
      it "returns only featured tracks" do
        featured1 = create(:track, :featured, artist: artist)
        featured2 = create(:track, :featured, artist: artist)
        create(:track, artist: artist, featured: false)

        expect(Track.featured).to contain_exactly(featured1, featured2)
      end
    end

    describe ".ordered" do
      it "orders featured tracks first" do
        create(:track, artist: artist, featured: false, release_date: Date.today)
        track2 = create(:track, artist: artist, featured: true, release_date: Date.today - 1.year)

        expect(Track.ordered.first).to eq(track2)
      end

      it "orders by release_date descending within same featured status" do
        track1 = create(:track, artist: artist, featured: true, release_date: Date.today - 1.year)
        track2 = create(:track, artist: artist, featured: true, release_date: Date.today)
        track3 = create(:track, artist: artist, featured: false, release_date: Date.today)
        track4 = create(:track, artist: artist, featured: false, release_date: Date.today - 1.month)

        ordered = Track.ordered
        expect(ordered[0]).to eq(track2) # Featured, newest
        expect(ordered[1]).to eq(track1) # Featured, older
        expect(ordered[2]).to eq(track3) # Not featured, newest
        expect(ordered[3]).to eq(track4) # Not featured, older
      end

      it "handles tracks without release_date (NULLS LAST)" do
        track1 = create(:track, artist: artist, featured: false, release_date: Date.today)
        track2 = create(:track, artist: artist, featured: false, release_date: nil)

        ordered = Track.ordered.to_a
        expect(ordered.first).to eq(track1)
        expect(ordered.last).to eq(track2)
      end
    end

    describe ".visible_in_pulse_vault" do
      it "returns only tracks with show_in_pulse_vault true" do
        vault_track1 = create(:track, artist: artist, show_in_pulse_vault: true)
        vault_track2 = create(:track, artist: artist, show_in_pulse_vault: true)
        create(:track, artist: artist, show_in_pulse_vault: false)

        expect(Track.visible_in_pulse_vault).to contain_exactly(vault_track1, vault_track2)
      end
    end

    describe ".album_order" do
      it "orders by track_number ascending" do
        album = create(:album)
        track3 = create(:track, album: album, track_number: 3, title: "C")
        track1 = create(:track, album: album, track_number: 1, title: "A")
        track2 = create(:track, album: album, track_number: 2, title: "B")

        ordered = Track.album_order.to_a
        expect(ordered[0]).to eq(track1)
        expect(ordered[1]).to eq(track2)
        expect(ordered[2]).to eq(track3)
      end

      it "falls back to title when track_number is same or nil" do
        album = create(:album)
        track_c = create(:track, album: album, track_number: nil, title: "C Track")
        track_a = create(:track, album: album, track_number: nil, title: "A Track")
        track_b = create(:track, album: album, track_number: nil, title: "B Track")

        ordered = Track.album_order.to_a
        expect(ordered[0]).to eq(track_a)
        expect(ordered[1]).to eq(track_b)
        expect(ordered[2]).to eq(track_c)
      end
    end
  end

  describe "#to_param" do
    it "returns the slug" do
      track = build(:track, slug: "my-track-slug")
      expect(track.to_param).to eq("my-track-slug")
    end
  end

  describe "full track lifecycle" do
    it "creates a track with all attributes" do
      artist = create(:artist, :xeraen)
      album = create(:album, artist: artist, name: "Best Album", album_type: "album")
      track = Track.create!(
        artist: artist,
        album: album,
        title: "Epic Song",
        slug: "epic-song",
        track_number: 3,
        release_date: Date.new(2024, 1, 15),
        duration: "4:20",
        featured: true,
        streaming_links: {
          spotify: "https://spotify.com/track/123",
          apple_music: "https://music.apple.com/track/123",
          youtube: "https://youtube.com/watch?v=123"
        },
        videos: {
          music: "https://youtube.com/watch?v=music123",
          lyric: "https://youtube.com/watch?v=lyric123"
        },
        lyrics: "Verse 1\nChorus\nVerse 2"
      )

      expect(track).to be_persisted
      expect(track.artist).to eq(artist)
      expect(track.album).to eq(album)
      expect(track.track_number).to eq(3)
      expect(track.featured).to be true
      expect(track.streaming_links["spotify"]).to eq("https://spotify.com/track/123")
    end
  end

  describe "Active Storage audio_file" do
    let(:artist) { create(:artist) }
    let(:album) { create(:album, artist: artist) }
    let(:track) { create(:track, artist: artist, album: album) }

    it "can attach an audio file" do
      track.audio_file.attach(
        io: File.open(Rails.root.join("spec", "fixtures", "files", "test_audio.mp3")),
        filename: "test_audio.mp3",
        content_type: "audio/mpeg"
      )

      expect(track.audio_file).to be_attached
    end

    it "can have no audio file" do
      expect(track.audio_file).not_to be_attached
    end

    it "returns the correct content type" do
      track.audio_file.attach(
        io: File.open(Rails.root.join("spec", "fixtures", "files", "test_audio.mp3")),
        filename: "test_audio.mp3",
        content_type: "audio/mpeg"
      )

      expect(track.audio_file.content_type).to eq("audio/mpeg")
    end

    it "returns the correct filename" do
      track.audio_file.attach(
        io: File.open(Rails.root.join("spec", "fixtures", "files", "test_audio.mp3")),
        filename: "test_audio.mp3",
        content_type: "audio/mpeg"
      )

      expect(track.audio_file.filename.to_s).to eq("test_audio.mp3")
    end

    it "can be purged" do
      track.audio_file.attach(
        io: File.open(Rails.root.join("spec", "fixtures", "files", "test_audio.mp3")),
        filename: "test_audio.mp3",
        content_type: "audio/mpeg"
      )

      expect(track.audio_file).to be_attached
      track.audio_file.purge
      expect(track.audio_file).not_to be_attached
    end
  end
end
