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
end
