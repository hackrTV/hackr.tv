require "rails_helper"

RSpec.describe NavigationHelper, type: :helper do
  # Phase 7 decommission: the HOTWIRE_PATHS registry is gone. nav_link_to
  # must never emit data-turbo=false — a full page load kills the
  # permanent audio player, so every nav link stays Turbo-navigable.
  describe "#nav_link_to" do
    it "renders a plain Turbo-navigable link" do
      html = helper.nav_link_to("/vault") { "VAULT" }
      expect(html).to include('href="/vault"')
      expect(html).to include("VAULT")
      expect(html).not_to include("data-turbo")
    end

    it "passes the css class through" do
      html = helper.nav_link_to("/wire", css_class: "nav-item") { "WIRE" }
      expect(html).to include('class="nav-item"')
      expect(html).not_to include("data-turbo")
    end
  end

  describe "#nav_active?" do
    it "matches root exactly and other paths by prefix" do
      allow(helper.request).to receive(:path).and_return("/")
      expect(helper.nav_active?("/")).to be(true)
      expect(helper.nav_active?("/vault")).to be(false)

      allow(helper.request).to receive(:path).and_return("/fm/radio")
      expect(helper.nav_active?("/fm")).to be(true)
      expect(helper.nav_active?("/")).to be(false)
    end
  end
end
