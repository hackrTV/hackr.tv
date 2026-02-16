# == Schema Information
#
# Table name: releases
# Database name: primary
#
#  id             :integer          not null, primary key
#  catalog_number :string
#  classification :string
#  credits        :text
#  description    :text
#  label          :string
#  media_format   :string
#  name           :string           not null
#  notes          :text
#  release_date   :date
#  release_type   :string
#  slug           :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  artist_id      :integer          not null
#
# Indexes
#
#  index_releases_on_artist_id           (artist_id)
#  index_releases_on_artist_id_and_slug  (artist_id,slug) UNIQUE
#
# Foreign Keys
#
#  artist_id  (artist_id => artists.id)
#
require "rails_helper"

RSpec.describe Release, type: :model do
  describe "associations" do
    it "belongs to an artist" do
      association = Release.reflect_on_association(:artist)
      expect(association.macro).to eq(:belongs_to)
    end

    it "has many tracks" do
      association = Release.reflect_on_association(:tracks)
      expect(association.macro).to eq(:has_many)
    end

    it "has dependent restrict_with_error on tracks" do
      association = Release.reflect_on_association(:tracks)
      expect(association.options[:dependent]).to eq(:restrict_with_error)
    end
  end

  describe "validations" do
    let(:artist) { create(:artist) }

    it "is valid with valid attributes" do
      release = build(:release, artist: artist)
      expect(release).to be_valid
    end

    it "is invalid without a name" do
      release = build(:release, artist: artist, name: nil)
      expect(release).not_to be_valid
      expect(release.errors[:name]).to include("can't be blank")
    end

    it "is invalid without a slug" do
      release = build(:release, artist: artist, slug: nil)
      expect(release).not_to be_valid
      expect(release.errors[:slug]).to include("can't be blank")
    end

    it "is invalid without an artist" do
      release = build(:release, artist: nil)
      expect(release).not_to be_valid
    end

    it "requires unique slug scoped to artist" do
      create(:release, artist: artist, slug: "unique-release")
      duplicate = build(:release, artist: artist, slug: "unique-release")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:slug]).to include("has already been taken")
    end

    it "allows same slug for different artists" do
      artist1 = create(:artist, slug: "artist-1")
      artist2 = create(:artist, slug: "artist-2")
      create(:release, artist: artist1, slug: "same-slug")
      duplicate = build(:release, artist: artist2, slug: "same-slug")
      expect(duplicate).to be_valid
    end
  end

  describe "#to_param" do
    it "returns the slug" do
      release = build(:release, slug: "my-release-slug")
      expect(release.to_param).to eq("my-release-slug")
    end
  end

  describe "dependent restrict_with_error behavior" do
    it "prevents deletion when release has tracks" do
      artist = create(:artist)
      release = create(:release, artist: artist)
      create(:track, artist: artist, release: release)

      expect { release.destroy }.not_to change { Release.count }
      expect(release.errors[:base]).to include("Cannot delete record because dependent tracks exist")
    end

    it "allows deletion when release has no tracks" do
      release = create(:release)
      expect { release.destroy }.to change { Release.count }.by(-1)
    end
  end

  describe "track ordering" do
    it "orders tracks by track_number" do
      artist = create(:artist)
      release = create(:release, artist: artist)
      track3 = create(:track, artist: artist, release: release, track_number: 3, title: "Third Track")
      track1 = create(:track, artist: artist, release: release, track_number: 1, title: "First Track")
      create(:track, artist: artist, release: release, track_number: 2, title: "Second Track")

      expect(release.tracks.pluck(:track_number)).to eq([1, 2, 3])
      expect(release.tracks.first).to eq(track1)
      expect(release.tracks.last).to eq(track3)
    end

    it "orders tracks by title when track_number is nil" do
      artist = create(:artist)
      release = create(:release, artist: artist)
      create(:track, artist: artist, release: release, track_number: nil, title: "C Track")
      create(:track, artist: artist, release: release, track_number: nil, title: "A Track")
      create(:track, artist: artist, release: release, track_number: nil, title: "B Track")

      expect(release.tracks.pluck(:title)).to eq(["A Track", "B Track", "C Track"])
    end
  end

  describe "full release lifecycle" do
    it "creates a release with all attributes" do
      artist = create(:artist)
      release = Release.create!(
        artist: artist,
        name: "Power-On Self-Test",
        slug: "power-on-self-test",
        release_type: "album",
        release_date: Date.new(2024, 10, 17),
        description: "A cyberpunk concept album exploring dystopian futures"
      )

      expect(release).to be_persisted
      expect(release.artist).to eq(artist)
      expect(release.name).to eq("Power-On Self-Test")
      expect(release.release_type).to eq("album")
      expect(release.cover_image.attached?).to be false
    end
  end

  describe "Active Storage cover_image" do
    let(:artist) { create(:artist) }

    it "can attach a cover image" do
      release = create(:release, artist: artist)
      release.cover_image.attach(
        io: File.open(Rails.root.join("spec", "fixtures", "files", "test_cover.jpg")),
        filename: "test_cover.jpg",
        content_type: "image/jpeg"
      )

      expect(release.cover_image).to be_attached
    end

    it "can have no cover image" do
      release = create(:release, artist: artist)
      expect(release.cover_image).not_to be_attached
    end

    it "returns the correct content type" do
      release = create(:release, artist: artist)
      release.cover_image.attach(
        io: File.open(Rails.root.join("spec", "fixtures", "files", "test_cover.jpg")),
        filename: "test_cover.jpg",
        content_type: "image/jpeg"
      )

      expect(release.cover_image.content_type).to eq("image/jpeg")
    end

    it "returns the correct filename" do
      release = create(:release, artist: artist)
      release.cover_image.attach(
        io: File.open(Rails.root.join("spec", "fixtures", "files", "test_cover.jpg")),
        filename: "test_cover.jpg",
        content_type: "image/jpeg"
      )

      expect(release.cover_image.filename.to_s).to eq("test_cover.jpg")
    end

    it "can be purged" do
      release = create(:release, artist: artist)
      release.cover_image.attach(
        io: File.open(Rails.root.join("spec", "fixtures", "files", "test_cover.jpg")),
        filename: "test_cover.jpg",
        content_type: "image/jpeg"
      )

      expect(release.cover_image).to be_attached
      release.cover_image.purge
      expect(release.cover_image).not_to be_attached
    end

    describe ":with_cover factory trait" do
      it "creates a release with attached cover image" do
        release = create(:release, :with_cover, artist: artist)

        expect(release.cover_image).to be_attached
        expect(release.cover_image.filename.to_s).to eq("test_cover.jpg")
        expect(release.cover_image.content_type).to eq("image/jpeg")
      end

      it "can be used with build strategy" do
        release = build(:release, :with_cover, artist: artist)
        release.save!

        expect(release.cover_image).to be_attached
      end
    end
  end
end
