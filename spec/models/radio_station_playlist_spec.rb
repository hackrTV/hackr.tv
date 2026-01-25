# == Schema Information
#
# Table name: radio_station_playlists
# Database name: primary
#
#  id               :integer          not null, primary key
#  position         :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  playlist_id      :integer          not null
#  radio_station_id :integer          not null
#
# Indexes
#
#  index_radio_station_playlists_on_playlist_id       (playlist_id)
#  index_radio_station_playlists_on_radio_station_id  (radio_station_id)
#  index_radio_station_playlists_position             (radio_station_id,position)
#  index_radio_station_playlists_unique               (radio_station_id,playlist_id) UNIQUE
#
# Foreign Keys
#
#  playlist_id       (playlist_id => playlists.id)
#  radio_station_id  (radio_station_id => radio_stations.id)
#
require "rails_helper"

RSpec.describe RadioStationPlaylist, type: :model do
  describe "associations" do
    it { should belong_to(:radio_station) }
    it { should belong_to(:playlist) }
  end

  describe "validations" do
    subject { build(:radio_station_playlist) }

    # Note: We don't test validate_presence_of(:position) because the before_validation
    # callback automatically assigns position when nil, so it's never truly nil
    it { should validate_numericality_of(:position).only_integer.is_greater_than(0) }

    it "validates uniqueness of playlist per station" do
      station = create(:radio_station)
      playlist = create(:playlist)
      create(:radio_station_playlist, radio_station: station, playlist: playlist)

      duplicate = build(:radio_station_playlist, radio_station: station, playlist: playlist)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:playlist_id]).to include("is already in this radio station")
    end

    it "allows same playlist on different stations" do
      playlist = create(:playlist)
      station1 = create(:radio_station)
      station2 = create(:radio_station)

      create(:radio_station_playlist, radio_station: station1, playlist: playlist)
      rsp2 = build(:radio_station_playlist, radio_station: station2, playlist: playlist)

      expect(rsp2).to be_valid
    end
  end

  describe "callbacks" do
    describe "auto-position assignment" do
      it "assigns position 1 for first playlist in station" do
        station = create(:radio_station)
        playlist = create(:playlist)

        rsp = RadioStationPlaylist.create(radio_station: station, playlist: playlist)

        expect(rsp.position).to eq(1)
      end

      it "assigns next available position" do
        station = create(:radio_station)
        playlist1 = create(:playlist)
        playlist2 = create(:playlist)
        playlist3 = create(:playlist)

        rsp1 = create(:radio_station_playlist, radio_station: station, playlist: playlist1)
        rsp2 = create(:radio_station_playlist, radio_station: station, playlist: playlist2)
        rsp3 = create(:radio_station_playlist, radio_station: station, playlist: playlist3)

        expect(rsp1.position).to eq(1)
        expect(rsp2.position).to eq(2)
        expect(rsp3.position).to eq(3)
      end

      it "does not override explicit position" do
        station = create(:radio_station)
        playlist1 = create(:playlist)
        playlist2 = create(:playlist)

        create(:radio_station_playlist, radio_station: station, playlist: playlist1, position: 1)
        rsp2 = create(:radio_station_playlist, radio_station: station, playlist: playlist2, position: 5)

        expect(rsp2.position).to eq(5)
      end

      it "assigns independent positions per station" do
        station1 = create(:radio_station)
        station2 = create(:radio_station)
        playlist1 = create(:playlist)
        playlist2 = create(:playlist)

        rsp1 = create(:radio_station_playlist, radio_station: station1, playlist: playlist1)
        rsp2 = create(:radio_station_playlist, radio_station: station2, playlist: playlist2)

        expect(rsp1.position).to eq(1)
        expect(rsp2.position).to eq(1) # Independent counter for station2
      end
    end
  end

  describe "ordering" do
    it "orders playlists by position within a station" do
      station = create(:radio_station)
      playlist1 = create(:playlist)
      playlist2 = create(:playlist)
      playlist3 = create(:playlist)

      # Create out of order
      rsp3 = create(:radio_station_playlist, radio_station: station, playlist: playlist3, position: 3)
      rsp1 = create(:radio_station_playlist, radio_station: station, playlist: playlist1, position: 1)
      rsp2 = create(:radio_station_playlist, radio_station: station, playlist: playlist2, position: 2)

      ordered = station.radio_station_playlists.order(position: :asc)

      expect(ordered[0]).to eq(rsp1)
      expect(ordered[1]).to eq(rsp2)
      expect(ordered[2]).to eq(rsp3)
    end
  end
end
