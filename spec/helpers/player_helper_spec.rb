require "rails_helper"

RSpec.describe PlayerHelper, type: :helper do
  describe "#artist_profile_path_for" do
    it "returns the artist's profile path, blank when there is none" do
      expect(helper.artist_profile_path_for(build(:artist, profile_path: "/xeraen/bio"))).to eq("/xeraen/bio")
      expect(helper.artist_profile_path_for(build(:artist, profile_path: nil))).to eq("")
    end
  end
end
