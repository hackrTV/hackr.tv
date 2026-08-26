require "rails_helper"

# Chat packet text rendering (Phase 5): WireTextRenderer's codex/link/
# censor rules plus @mention linking on plain segments.
RSpec.describe UplinkTextRenderer do
  def render(text, admin: false)
    described_class.render(text, poster_is_admin: admin)
  end

  describe "@mentions" do
    it "links mentions to /wire with a data-alias for self-highlighting" do
      html = render("ping @xeraen now")

      expect(html).to include(%(<a href="/wire/xeraen" class="uplink-mention" data-alias="xeraen">@xeraen</a>))
    end

    it "links mentions at the start of the string and after punctuation" do
      expect(render("@xeraen hi")).to include("uplink-mention")
      expect(render("(@xeraen)")).to include("uplink-mention")
    end

    it "does not mislink email local parts" do
      html = render("mail me@gmail.com ok")

      expect(html).not_to include("uplink-mention")
      expect(html).to include("me@gmail.com")
    end

    it "keeps mention case as typed" do
      expect(render("hey @XeRaEn")).to include(%(href="/wire/XeRaEn"))
    end
  end

  describe "URL censoring (inherited rules)" do
    it "censors bare URLs for non-admins, keeping trailing punctuation" do
      html = render("see https://example.com/x.")

      expect(html).to include("[LINK CENSORED BY GOVCORP]")
      expect(html).not_to include(%(href="https://example.com/x"))
      expect(html).to include("</span>.")
    end

    it "links URLs for admins" do
      html = render("see https://example.com/x", admin: true)

      expect(html).to include(%(<a href="https://example.com/x"))
      expect(html).to include('target="_blank"')
    end

    it "does not process mentions inside markdown link labels" do
      html = render("[@xeraen](https://example.com/x)", admin: true)

      expect(html).not_to include("uplink-mention")
      expect(html).to include(">@xeraen</a>")
    end
  end

  describe "codex links" do
    it "renders [[refs]] as codex links" do
      expect(render("read [[The Ride]]")).to include(%(href="/codex/the-ride"))
    end
  end

  describe "escaping" do
    it "escapes HTML around mentions and returns an html_safe string" do
      html = render("<b>@xeraen</b>")

      expect(html).to be_html_safe
      expect(html).to include("&lt;b&gt;")
      expect(html).to include("uplink-mention")
      expect(html).not_to include("<b>")
    end

    it "renders blank content as an empty string" do
      expect(render(nil)).to eq("")
      expect(render("")).to eq("")
    end
  end
end
