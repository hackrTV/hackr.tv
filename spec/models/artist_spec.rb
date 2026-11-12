# == Schema Information
#
# Table name: artists
# Database name: primary
#
#  id          :integer          not null, primary key
#  artist_type :string           default("band"), not null
#  genre       :string
#  name        :string
#  position    :integer
#  slug        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_artists_on_position  (position)
#  index_artists_on_slug      (slug) UNIQUE
#
require "rails_helper"

RSpec.describe Artist, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      artist = Artist.new(name: "Test Artist", slug: "test-artist")
      expect(artist).to be_valid
    end

    it "is invalid without a name" do
      artist = Artist.new(slug: "test-artist")
      expect(artist).not_to be_valid
    end

    it "is invalid without a slug" do
      artist = Artist.new(name: "Test Artist")
      expect(artist).not_to be_valid
    end

    it "requires unique slug" do
      Artist.create!(name: "First Artist", slug: "unique-slug")
      duplicate = Artist.new(name: "Second Artist", slug: "unique-slug")
      expect(duplicate).not_to be_valid
    end
  end

  describe "position" do
    it "allows a blank or non-negative whole number" do
      expect(build(:artist, position: nil)).to be_valid
      expect(build(:artist, position: 0)).to be_valid
      expect(build(:artist, position: -1)).not_to be_valid
      expect(build(:artist, position: 1.5)).not_to be_valid
    end
  end

  describe ".ordered" do
    it "lists positioned artists by position, then the rest by name case-insensitively" do
      zed = create(:artist, name: "Zed", position: 1)
      alpha = create(:artist, name: "alpha", position: 2)
      bravo = create(:artist, name: "Bravo")
      charlie = create(:artist, name: "charlie")
      ace = create(:artist, name: "Ace", position: 0)

      expect(Artist.ordered.to_a).to eq([ace, zed, alpha, bravo, charlie])
    end

    it "breaks a tie on position and name by id" do
      first = create(:artist, name: "echo", position: 1)
      second = create(:artist, name: "Echo", position: 1)

      expect(Artist.ordered.to_a).to eq([first, second])
    end
  end

  describe "associations" do
    it "has many tracks" do
      association = Artist.reflect_on_association(:tracks)
      expect(association.macro).to eq(:has_many)
    end
  end

  describe "#to_param" do
    it "returns the slug" do
      artist = Artist.new(name: "Test Artist", slug: "test-artist")
      expect(artist.to_param).to eq("test-artist")
    end
  end

  describe "genre field" do
    it "is valid with a genre" do
      artist = create(:artist, genre: "Synthwave/Cyberpunk")
      expect(artist).to be_valid
      expect(artist.genre).to eq("Synthwave/Cyberpunk")
    end

    it "is valid without a genre" do
      artist = create(:artist, genre: nil)
      expect(artist).to be_valid
      expect(artist.genre).to be_nil
    end

    it "can be updated" do
      artist = create(:artist, genre: "Rock")
      artist.update(genre: "Electronic")
      expect(artist.genre).to eq("Electronic")
    end

    it "persists genre across reloads" do
      artist = create(:artist, genre: "Industrial/Dark Synth")
      artist.reload
      expect(artist.genre).to eq("Industrial/Dark Synth")
    end

    describe "factory traits" do
      it "thecyberpulse trait sets genre to Synthwave/Cyberpunk" do
        artist = create(:artist, :thecyberpulse)
        expect(artist.genre).to eq("Synthwave/Cyberpunk")
      end

      it "xeraen trait sets genre to Industrial/Dark Synth" do
        artist = create(:artist, :xeraen)
        expect(artist.genre).to eq("Industrial/Dark Synth")
      end
    end
  end
end
