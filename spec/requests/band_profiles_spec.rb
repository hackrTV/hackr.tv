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
      expect(response.body).to include('href="/vault?artist=system-rot"')
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
      expect(response.body).to include('href="/vault?artist=voiceprint"')
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
      expect(response.body).to include('href="/vault?artist=blitzbeam"')
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
      expect(response.body).to include('href="/vault?artist=ethereality"')
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
      expect(response.body).to include('href="/vault?artist=offline"')
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
      expect(response.body).to include('href="/vault?artist=injection-vector"')
    end
  end

  describe "GET /cipher-protocol" do
    it "renders the Cipher Protocol profile" do
      get "/cipher-protocol"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("CIPHER PROTOCOL")
      expect(response.body).to include("[:: THE DATA COURIERS ::]")
      expect(response.body).to include("OPERATIONAL PARAMETERS")
      expect(response.body).to include('href="/vault?artist=cipher-protocol"')
    end
  end

  describe "GET /apex-overdrive" do
    it "renders the Apex Overdrive profile" do
      get "/apex-overdrive"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("APEX OVERDRIVE")
      expect(response.body).to include("⚡ EUPHORIA AS DEFIANCE ⚡")
      expect(response.body).to include("THE SUMMIT PHILOSOPHY")
      expect(response.body).to include('href="/vault?artist=apex-overdrive"')
    end
  end

  describe "GET /neon-hearts" do
    it "renders the Neon Hearts profile" do
      get "/neon-hearts"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("NEON HEARTS (ネオンハーツ)")
      expect(response.body).to include("💖 Sugar-Coated Revolution 💖")
      expect(response.body).to include("💖 The Cute Rebellion 💖")
      expect(response.body).to include('href="/vault?artist=neon-hearts"')
    end
  end

  describe "GET /temporal-blue-drift" do
    it "renders the Temporal Blue Drift profile" do
      get "/temporal-blue-drift"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("TEMPORAL BLUE DRIFT")
      expect(response.body).to include("WHAT I'M TRYING TO TELL YOU")
      expect(response.body).to include("A Hundred Years Between")
      expect(response.body).to include('href="/vault?artist=temporal-blue-drift"')
    end
  end

  describe "GET /heartbreak-havoc" do
    it "renders the heartbreak_havoc.sh profile" do
      get "/heartbreak-havoc"

      expect(response).to have_http_status(:success)
      expect(response.body).to include("HEARTBREAK_HAVOC.SH")
      expect(response.body).to include("TACTICAL DOCTRINE")
      expect(response.body).to include("Nightcore Assault")
      expect(response.body).to include('href="/vault?artist=heartbreak-havoc"')
    end
  end

  describe "GET /synthia (a DB artist outside the routed slug list)" do
    it "renders the Coming Soon console screen with a 200" do
      create(:artist, name: "Synthia", slug: "synthia", genre: "Synth Pop")

      get "/synthia"

      expect(response).to have_http_status(:ok)
      body = response.body
      expect(body).to include("<title>Synthia — hackr.tv</title>")
      expect(body).to include('class="console" data-controller="terminal" data-boot="pending"')
      expect(body).not_to include("chrome-ascii", "tui-window", "band-profile")
      expect(body).to include("PROFILE PENDING", "SYNTH POP", "◌ PROFILE COMING SOON", "// TRANSMISSION PENDING //")
      expect(body).to include(%(<a class="console-bar-link" href="/synthia/releases">[&gt;] RELEASES</a>))
      expect(body).to include(%(data-command="releases" href="/synthia/releases">Releases</a>))
      expect(body).to include(%(data-command="vault" href="/vault?artist=synthia">Pulse Vault</a>))
      expect(body).to include(%(data-command="fnet" href="/f/net">Fracture Network</a>))
      expect(body).to include("(releases vault fnet home)")
      expect(body).not_to include("xt-hero")
    end

    it "shows the artist image when one is attached" do
      synthia = create(:artist, name: "Synthia", slug: "synthia")
      synthia.hero_image.attach(io: File.open(Rails.root.join("spec/fixtures/files/test_cover.jpg")), filename: "synthia.jpg", content_type: "image/jpeg")

      get "/synthia"

      expect(response.body).to include('class="xt-hero console-line"', 'class="xt-hero-img"', "/synthia.jpg")
      expect(response.body.index("xt-hero")).to be < response.body.index("// TRANSMISSION PENDING //")
    end

    it "404s for a slug no artist has" do
      get "/no-such-band"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /the-pulse-grid (routed slug without a profile)" do
    it "renders the Coming Soon screen under the upcased slug when no artist row exists" do
      get "/the-pulse-grid"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<title>THE-PULSE-GRID — hackr.tv</title>")
      expect(response.body).to include("◌ PROFILE COMING SOON")
      expect(response.body).to include(%(href="/the-pulse-grid/releases"))
      expect(response.body).not_to include("GENRE")
    end

    it "shows the artist row's name and genre when one exists" do
      create(:artist, name: "The Pulse Grid", slug: "the-pulse-grid", genre: "Canon")

      get "/the-pulse-grid"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("<title>The Pulse Grid — hackr.tv</title>", "◌ PROFILE COMING SOON", "CANON")
    end
  end

  describe "GET /vault with an artist whose slug collides with the route" do
    it "is still served by the named route" do
      create(:artist, name: "Vault", slug: "vault")

      get "/vault"

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("PROFILE COMING SOON")
    end
  end
end
