require "rails_helper"

# Phase 4: Hotwire band profile pages (replaces BandProfilePage.tsx,
# BandProfileLayout.tsx, and the five migrated bandProfileConfig.tsx
# entries). These paths hit pages#spa_root until the Phase 4 routes pass
# points each artist scope root at band_profiles#show, so this spec is
# expected red until then.
RSpec.describe "Band profile pages", type: :request do
  describe "GET /system-rot" do
    it "renders the System Rot profile without the SPA shell" do
      create(:artist, name: "System Rot", slug: "system-rot")

      get "/system-rot"

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('<div id="root">')
      expect(response.body).to include("SYSTEM ROT")
      expect(response.body).to include("WE WERE HERE")
      expect(response.body).to include("WHAT WE BELIEVE")
      expect(response.body).to include("band-profile--system-rot")
      expect(response.body).to include('data-controller="bio-credit"')
      expect(response.body).to include('data-bio-credit-slug-value="system-rot"')
    end

    it "links the three footer navigation targets" do
      get "/system-rot"

      expect(response.body).to include("← BACK TO FRACTURE NETWORK")
      expect(response.body).to include('href="/f/net"')
      expect(response.body).to include('href="/system-rot/releases"')
      expect(response.body).to include('href="/vault?filter=system%20rot"')
      expect(response.body).to include('<span class="chrome-desktop-only">LISTEN IN THE PULSE VAULT →</span>')
      expect(response.body).to include('<span class="chrome-mobile-only">PULSE VAULT →</span>')
    end
  end

  describe "GET /voiceprint" do
    it "renders the Voiceprint archive profile" do
      get "/voiceprint"

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('<div id="root">')
      expect(response.body).to include("VOICEPRINT")
      expect(response.body).to include("VP-#{Date.current.year + 100}-INTRO")
      expect(response.body).to include("THE ARCHIVE PROJECT")
      expect(response.body).to include("[STATUS: FRAGMENTATION_AND_RECONSTRUCTION]")
      expect(response.body).to include('href="/vault?filter=voiceprint"')
    end
  end

  describe "GET /blitzbeam" do
    it "renders the BlitzBeam+ profile" do
      get "/blitzbeam"

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('<div id="root">')
      expect(response.body).to include("BLITZBEAM+")
      expect(response.body).to include("⚡ SPEED IS LIFE! ⚡")
      expect(response.body).to include("THE VELOCITY+ PHILOSOPHY")
      expect(response.body).to include('href="/blitzbeam/releases"')
      expect(response.body).to include('href="/vault?filter=blitzbeam"')
    end
  end

  describe "GET /ethereality" do
    it "renders the Ethereality profile with the year interpolations" do
      get "/ethereality"

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('<div id="root">')
      expect(response.body).to include("ETHEREALITY")
      expect(response.body).to include("✦ Trance States, Unconstrained ✦")
      expect(response.body).to include("Encounter with the Deep")
      expect(response.body).to include("XERAEN in #{Date.current.year + 100} reaching back to Ashlinn in #{Date.current.year}.")
      expect(response.body).to include('href="/vault?filter=ethereality"')
    end
  end

  describe "GET /offline" do
    it "renders the Offline profile" do
      get "/offline"

      expect(response).to have_http_status(:success)
      expect(response.body).not_to include('<div id="root">')
      expect(response.body).to include("OFFLINE")
      expect(response.body).to include("Authenticity Through Disconnection")
      expect(response.body).to include("The Unplugged Philosophy")
      expect(response.body).to include('href="/vault?filter=offline"')
    end
  end

  describe "GET /temporal-blue-drift (unconfigured slug)" do
    it "renders the minimal not-found page with a 200 like the SPA" do
      get "/temporal-blue-drift"

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('<div id="root">')
      expect(response.body).to include("Band not found")
    end
  end
end
