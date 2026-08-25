require "rails_helper"

RSpec.describe NavigationHelper, type: :helper do
  # HOTWIRE_PATHS gates nav_link_to: unlisted paths get data-turbo=false →
  # a FULL page load, which kills the permanent audio player. Every
  # Hotwire-served route family must be listed. (Phase 4 regression: the
  # artist slugs were missed, so navigating to /thecyberpulse or /xeraen
  # from the vault stopped playback.)
  describe "#hotwire_path?" do
    it "covers the whole Phase 4 music cluster, including every artist slug" do
      %w[
        /vault /fm /fm/radio /fm/releases /fm/playlists /f/net
        /shared/some-token /sector/x
        /thecyberpulse /thecyberpulse/bio /thecyberpulse/releases /thecyberpulse/vidz
        /xeraen /xeraen/bio /xeraen/releases
        /system-rot /wavelength-zero /voiceprint /temporal-blue-drift
        /injection-vector /cipher-protocol /blitzbeam /apex-overdrive
        /ethereality /neon-hearts /offline /heartbreak-havoc /the-pulse-grid
        /system-rot/releases /blitzbeam/trackz/some-track
      ].each do |path|
        expect(helper.hotwire_path?(path)).to be(true), "expected #{path} to be a Hotwire path"
      end
    end

    it "keeps still-React routes as full page loads" do
      %w[/grid /grid/1337 /uplink /achievements /missions /deck /transit].each do |path|
        expect(helper.hotwire_path?(path)).to be(false), "expected #{path} to stay non-Turbo"
      end
    end

    it "does not let the root entry swallow other paths" do
      expect(helper.hotwire_path?("/")).to be(true)
      expect(helper.hotwire_path?("/grid")).to be(false)
    end
  end
end
