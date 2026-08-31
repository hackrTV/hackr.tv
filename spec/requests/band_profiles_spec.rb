require "rails_helper"

# Phase 4: Hotwire band profile pages (replaces BandProfilePage.tsx,
# BandProfileLayout.tsx, and the migrated bandProfileConfig.tsx entries —
# all eleven since the post-launch port of the six the Phase 4 pass
# missed). Slugs routed to band_profiles#show but absent from
# BandProfile::CONFIG fall back to the not-found variant.
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

  describe "GET /injection-vector" do
    it "renders the Injection Vector profile" do
      get "/injection-vector"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("INJECTION VECTOR")
      expect(response.body).to include("[:: THE BREACH IN THE SYSTEM ::]")
      expect(response.body).to include("TACTICAL DOCTRINE")
      expect(response.body).to include("band-profile--injection-vector")
      expect(response.body).to include('href="/vault?filter=injection%20vector"')
    end
  end

  describe "GET /cipher-protocol" do
    it "renders the Cipher Protocol profile" do
      get "/cipher-protocol"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("CIPHER PROTOCOL")
      expect(response.body).to include("[:: THE DATA COURIERS ::]")
      expect(response.body).to include("OPERATIONAL PARAMETERS")
      expect(response.body).to include('href="/vault?filter=cipher%20protocol"')
    end
  end

  describe "GET /apex-overdrive" do
    it "renders the Apex Overdrive profile" do
      get "/apex-overdrive"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("APEX OVERDRIVE")
      expect(response.body).to include("⚡ EUPHORIA AS DEFIANCE ⚡")
      expect(response.body).to include("THE SUMMIT PHILOSOPHY")
      expect(response.body).to include('href="/vault?filter=apex%20overdrive"')
    end
  end

  describe "GET /neon-hearts" do
    it "renders the Neon Hearts profile" do
      get "/neon-hearts"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("NEON HEARTS (ネオンハーツ)")
      expect(response.body).to include("💖 Sugar-Coated Revolution 💖")
      expect(response.body).to include("💖 The Cute Rebellion 💖")
      expect(response.body).to include('href="/vault?filter=neon%20hearts"')
    end
  end

  describe "GET /temporal-blue-drift" do
    it "renders the Temporal Blue Drift profile" do
      get "/temporal-blue-drift"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("TEMPORAL BLUE DRIFT")
      expect(response.body).to include("WHAT I'M TRYING TO TELL YOU")
      expect(response.body).to include("A Hundred Years Between")
      expect(response.body).to include('href="/vault?filter=temporal%20blue%20drift"')
    end
  end

  describe "GET /heartbreak-havoc" do
    it "renders the heartbreak_havoc.sh profile" do
      get "/heartbreak-havoc"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("HEARTBREAK_HAVOC.SH")
      expect(response.body).to include("TACTICAL DOCTRINE")
      expect(response.body).to include("Nightcore Assault")
      expect(response.body).to include('href="/vault?filter=heartbreak%20havoc"')
    end
  end

  describe "GET /the-pulse-grid (unconfigured slug)" do
    it "renders the minimal not-found page with a 200 like the SPA" do
      get "/the-pulse-grid"

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('<div id="root">')
      expect(response.body).to include("Band not found")
    end
  end
end
