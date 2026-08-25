require "rails_helper"

# Mirrors the SPA's WireText.test.tsx cases — the server renderer must
# match the client pipeline it replaces (Hotwire migration Phase 3).
RSpec.describe WireTextRenderer do
  def render(content, admin: false)
    described_class.render(content, poster_is_admin: admin)
  end

  describe "admin posters" do
    it "linkifies a bare URL" do
      html = render("Check https://example.com out", admin: true)

      expect(html).to include('<a href="https://example.com"')
      expect(html).to include('target="_blank"')
      expect(html).to include('rel="noopener noreferrer"')
      expect(html).to include("Check ")
      expect(html).to include(" out")
    end

    it "renders a markdown link with its label" do
      html = render("See [my site](https://example.com) here", admin: true)

      expect(html).to include('<a href="https://example.com"')
      expect(html).to include(">my site</a>")
      expect(html).not_to include("[my site]")
    end

    it "renders URLs and codex links together" do
      create(:codex_entry, :published, name: "GovCorp")

      html = render("Visit https://example.com and read about [[GovCorp]]", admin: true)

      expect(html).to include('<a href="https://example.com"')
      expect(html).to include('<a href="/codex/govcorp"')
      expect(html).to include(">GovCorp</a>")
    end
  end

  describe "non-admin posters" do
    it "censors a bare URL (URL not in output)" do
      html = render("Check https://example.com out")

      expect(html).to include("[LINK CENSORED BY GOVCORP]")
      expect(html).not_to include("example.com")
      expect(html).to include("Check ")
      expect(html).to include(" out")
    end

    it "censors a markdown link, dropping its display text" do
      html = render("See [my site](https://example.com) here")

      expect(html).to include("[LINK CENSORED BY GOVCORP]")
      expect(html).not_to include("my site")
      expect(html).not_to include("example.com")
    end

    it "keeps codex links working around censored URLs" do
      create(:codex_entry, :published, name: "GovCorp")

      html = render("Visit https://example.com and read about [[GovCorp]]")

      expect(html).to include("[LINK CENSORED BY GOVCORP]")
      expect(html).to include('<a href="/codex/govcorp"')
    end

    it "keeps trailing sentence punctuation outside the censor" do
      html = render("Read https://example.com/page.")

      expect(html).to include("[LINK CENSORED BY GOVCORP]")
      expect(html).to match(/GOVCORP\]<\/span>\./)
    end
  end

  describe "plain content" do
    it "passes plain text through unchanged" do
      expect(render("Just a normal message")).to eq("Just a normal message")
    end

    it "renders codex links without URLs" do
      create(:codex_entry, :published, name: "GovCorp")

      html = render("Learn about [[GovCorp]] today")

      expect(html).to include('<a href="/codex/govcorp"')
    end

    it "honors the [[Name|display]] pipe override" do
      html = render("The [[GovCorp|Corp]] watches")

      expect(html).to include('<a href="/codex/govcorp"')
      expect(html).to include(">Corp</a>")
    end

    it "escapes HTML in content" do
      html = render("<script>alert(1)</script>")

      expect(html).not_to include("<script>")
      expect(html).to include("&lt;script&gt;")
    end

    it "returns empty for blank content" do
      expect(render(nil)).to eq("")
      expect(render("")).to eq("")
    end
  end
end
