# == Schema Information
#
# Table name: albums
# Database name: primary
#
#  id           :integer          not null, primary key
#  album_type   :string
#  description  :text
#  name         :string           not null
#  release_date :date
#  slug         :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  artist_id    :integer          not null
#
# Indexes
#
#  index_albums_on_artist_id           (artist_id)
#  index_albums_on_artist_id_and_slug  (artist_id,slug) UNIQUE
#
# Foreign Keys
#
#  artist_id  (artist_id => artists.id)
#
require "rails_helper"

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
      create(:track, artist: artist, album: album, track_number: 2, title: "Second Track")

      expect(album.tracks.pluck(:track_number)).to eq([1, 2, 3])
      expect(album.tracks.first).to eq(track1)
      expect(album.tracks.last).to eq(track3)
    end

    it "orders tracks by title when track_number is nil" do
      artist = create(:artist)
      album = create(:album, artist: artist)
      create(:track, artist: artist, album: album, track_number: nil, title: "C Track")
      create(:track, artist: artist, album: album, track_number: nil, title: "A Track")
      create(:track, artist: artist, album: album, track_number: nil, title: "B Track")

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

  describe "Active Storage cover_image" do
    let(:artist) { create(:artist) }

    it "can attach a cover image" do
      album = create(:album, artist: artist)
      album.cover_image.attach(
        io: File.open(Rails.root.join("spec", "fixtures", "files", "test_cover.jpg")),
        filename: "test_cover.jpg",
        content_type: "image/jpeg"
      )

      expect(album.cover_image).to be_attached
    end

    it "can have no cover image" do
      album = create(:album, artist: artist)
      expect(album.cover_image).not_to be_attached
    end

    it "returns the correct content type" do
      album = create(:album, artist: artist)
      album.cover_image.attach(
        io: File.open(Rails.root.join("spec", "fixtures", "files", "test_cover.jpg")),
        filename: "test_cover.jpg",
        content_type: "image/jpeg"
      )

      expect(album.cover_image.content_type).to eq("image/jpeg")
    end

    it "returns the correct filename" do
      album = create(:album, artist: artist)
      album.cover_image.attach(
        io: File.open(Rails.root.join("spec", "fixtures", "files", "test_cover.jpg")),
        filename: "test_cover.jpg",
        content_type: "image/jpeg"
      )

      expect(album.cover_image.filename.to_s).to eq("test_cover.jpg")
    end

    it "can be purged" do
      album = create(:album, artist: artist)
      album.cover_image.attach(
        io: File.open(Rails.root.join("spec", "fixtures", "files", "test_cover.jpg")),
        filename: "test_cover.jpg",
        content_type: "image/jpeg"
      )

      expect(album.cover_image).to be_attached
      album.cover_image.purge
      expect(album.cover_image).not_to be_attached
    end

    describe ":with_cover factory trait" do
      it "creates an album with attached cover image" do
        album = create(:album, :with_cover, artist: artist)

        expect(album.cover_image).to be_attached
        expect(album.cover_image.filename.to_s).to eq("test_cover.jpg")
        expect(album.cover_image.content_type).to eq("image/jpeg")
      end

      it "can be used with build strategy" do
        album = build(:album, :with_cover, artist: artist)
        album.save!

        expect(album.cover_image).to be_attached
      end
    end
  end
end
