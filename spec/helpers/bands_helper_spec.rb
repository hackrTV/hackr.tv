require "rails_helper"

RSpec.describe BandsHelper, type: :helper do
  describe "#band_description" do
    it "reads the artist's description, printing {year} as the lore year" do
      artist = build(:artist, description: "Transmitting from {year} to rally The Listeners.")

      expect(helper.band_description(artist)).to eq("Transmitting from #{Date.current.year + 100} to rally The Listeners.")
    end

    it "falls back to the network's line when the description is blank" do
      expect(helper.band_description(build(:artist, description: nil))).to eq("Broadcasting truth through sound.")
      expect(helper.band_description(build(:artist, description: " "))).to eq("Broadcasting truth through sound.")
    end
  end
end
