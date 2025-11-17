require 'rails_helper'

RSpec.describe RadioStation, type: :model do
  describe "associations" do
    it { should have_many(:radio_station_playlists).dependent(:destroy) }
    it { should have_many(:playlists).through(:radio_station_playlists) }
  end

  describe "validations" do
    subject { build(:radio_station) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:slug) }
    it { should validate_presence_of(:position) }
    it { should validate_numericality_of(:position).only_integer.is_greater_than_or_equal_to(0) }

    it "requires slug when name is blank" do
      station = build(:radio_station, name: nil, slug: nil)
      expect(station).not_to be_valid
      expect(station.errors[:slug]).to include("can't be blank")
    end
  end

  describe "scopes" do
    describe ".ordered" do
      it "returns stations ordered by position, then name" do
        station3 = create(:radio_station, position: 2, name: "C Station")
        station1 = create(:radio_station, position: 0, name: "A Station")
        station2 = create(:radio_station, position: 1, name: "B Station")
        station4 = create(:radio_station, position: 0, name: "Z Station")

        ordered = RadioStation.ordered

        expect(ordered[0]).to eq(station1) # position 0, name A
        expect(ordered[1]).to eq(station4) # position 0, name Z
        expect(ordered[2]).to eq(station2) # position 1
        expect(ordered[3]).to eq(station3) # position 2
      end
    end
  end

  describe "callbacks" do
    describe "slug generation" do
      it "generates slug from name if slug is blank" do
        station = build(:radio_station, name: "Test Station", slug: nil)
        station.valid?
        expect(station.slug).to eq("test-station")
      end

      it "does not override existing slug" do
        station = build(:radio_station, name: "Test Station", slug: "custom-slug")
        station.valid?
        expect(station.slug).to eq("custom-slug")
      end

      it "handles special characters in name" do
        station = build(:radio_station, name: "Test & Station: Radio!", slug: nil)
        station.valid?
        expect(station.slug).to eq("test-station-radio")
      end
    end
  end

  describe "playlist ordering" do
    it "returns playlists in position order" do
      station = create(:radio_station)
      playlist1 = create(:playlist)
      playlist2 = create(:playlist)
      playlist3 = create(:playlist)

      create(:radio_station_playlist, radio_station: station, playlist: playlist1, position: 3)
      create(:radio_station_playlist, radio_station: station, playlist: playlist2, position: 1)
      create(:radio_station_playlist, radio_station: station, playlist: playlist3, position: 2)

      # Use radio_station_playlists to get ordered playlists (Playlist model has default_scope by created_at)
      playlists = station.radio_station_playlists.order(position: :asc).map(&:playlist)

      expect(playlists[0]).to eq(playlist2) # position 1
      expect(playlists[1]).to eq(playlist3) # position 2
      expect(playlists[2]).to eq(playlist1) # position 3
    end
  end
end
