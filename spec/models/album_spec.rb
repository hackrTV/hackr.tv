require 'rails_helper'

RSpec.describe Album, type: :model do
  describe "associations" do
    it "belongs to an artist" do
      association = Album.reflect_on_association(:artist)
      expect(association.macro).to eq(:belongs_to)
    end

    it "has many tracks" do
      association = Album.reflect_on_association(:tracks)
      expect(association.macro).to eq(:has_many)
    end

    it "has dependent restrict_with_error on tracks" do
      association = Album.reflect_on_association(:tracks)
      expect(association.options[:dependent]).to eq(:restrict_with_error)
    end
  end

  describe "validations" do
    let(:artist) { create(:artist) }

    it "is valid with valid attributes" do
      album = build(:album, artist: artist)
      expect(album).to be_valid
    end

    it "is invalid without a name" do
      album = build(:album, artist: artist, name: nil)
      expect(album).not_to be_valid
      expect(album.errors[:name]).to include("can't be blank")
    end

    it "is invalid without a slug" do
      album = build(:album, artist: artist, slug: nil)
      expect(album).not_to be_valid
      expect(album.errors[:slug]).to include("can't be blank")
    end

    it "is invalid without an artist" do
      album = build(:album, artist: nil)
      expect(album).not_to be_valid
    end

    it "requires unique slug scoped to artist" do
      create(:album, artist: artist, slug: "unique-album")
      duplicate = build(:album, artist: artist, slug: "unique-album")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:slug]).to include("has already been taken")
    end

    it "allows same slug for different artists" do
      artist1 = create(:artist, slug: "artist-1")
      artist2 = create(:artist, slug: "artist-2")
      create(:album, artist: artist1, slug: "same-slug")
      duplicate = build(:album, artist: artist2, slug: "same-slug")
      expect(duplicate).to be_valid
    end
  end

  describe "#to_param" do
    it "returns the slug" do
      album = build(:album, slug: "my-album-slug")
      expect(album.to_param).to eq("my-album-slug")
    end
  end

  describe "dependent restrict_with_error behavior" do
    it "prevents deletion when album has tracks" do
      artist = create(:artist)
      album = create(:album, artist: artist)
      create(:track, artist: artist, album: album)

      expect { album.destroy }.not_to change { Album.count }
      expect(album.errors[:base]).to include("Cannot delete record because dependent tracks exist")
    end

    it "allows deletion when album has no tracks" do
      album = create(:album)
      expect { album.destroy }.to change { Album.count }.by(-1)
    end
  end

  describe "track ordering" do
    it "orders tracks by track_number" do
      artist = create(:artist)
      album = create(:album, artist: artist)
      track3 = create(:track, artist: artist, album: album, track_number: 3, title: "Third Track")
      track1 = create(:track, artist: artist, album: album, track_number: 1, title: "First Track")
      track2 = create(:track, artist: artist, album: album, track_number: 2, title: "Second Track")

      expect(album.tracks.pluck(:track_number)).to eq([1, 2, 3])
      expect(album.tracks.first).to eq(track1)
      expect(album.tracks.last).to eq(track3)
    end

    it "orders tracks by title when track_number is nil" do
      artist = create(:artist)
      album = create(:album, artist: artist)
      track_c = create(:track, artist: artist, album: album, track_number: nil, title: "C Track")
      track_a = create(:track, artist: artist, album: album, track_number: nil, title: "A Track")
      track_b = create(:track, artist: artist, album: album, track_number: nil, title: "B Track")

      expect(album.tracks.pluck(:title)).to eq(["A Track", "B Track", "C Track"])
    end
  end

  describe "full album lifecycle" do
    it "creates an album with all attributes" do
      artist = create(:artist)
      album = Album.create!(
        artist: artist,
        name: "Power-On Self-Test",
        slug: "power-on-self-test",
        album_type: "album",
        release_date: Date.new(2024, 10, 17),
        description: "A cyberpunk concept album exploring dystopian futures"
      )

      expect(album).to be_persisted
      expect(album.artist).to eq(artist)
      expect(album.name).to eq("Power-On Self-Test")
      expect(album.album_type).to eq("album")
      expect(album.cover_image.attached?).to be false
    end
  end
end
