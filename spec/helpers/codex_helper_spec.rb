require "rails_helper"

RSpec.describe CodexHelper, type: :helper do
  describe "#generate_slug" do
    it "converts text to lowercase" do
      expect(helper.generate_slug("XERAEN")).to eq("xeraen")
    end

    it "converts spaces to hyphens" do
      expect(helper.generate_slug("The Fracture Network")).to eq("the-fracture-network")
    end

    it "removes special characters" do
      expect(helper.generate_slug("[[Entry Name]]")).to eq("entry-name")
      expect(helper.generate_slug("Test!@#$%Entry")).to eq("testentry")
    end

    it "squeezes multiple hyphens" do
      expect(helper.generate_slug("Multiple   Spaces")).to eq("multiple-spaces")
    end

    it "strips leading and trailing hyphens" do
      expect(helper.generate_slug("-Edge Case-")).to eq("edge-case")
    end

    it "handles mixed case and symbols" do
      expect(helper.generate_slug("PRISM 2.0: The System")).to eq("prism-20-the-system")
    end
  end

  describe "#codex_linkify" do
    it "converts [[Entry Name]] to HTML link" do
      result = helper.codex_linkify("See [[XERAEN]] for details")
      expect(result).to include('<a href="/codex/xeraen">XERAEN</a>')
    end

    it "handles multiple links" do
      result = helper.codex_linkify("[[XERAEN]] works with [[The Fracture Network]]")
      expect(result).to include('<a href="/codex/xeraen">XERAEN</a>')
      expect(result).to include('<a href="/codex/the-fracture-network">The Fracture Network</a>')
    end

    it "adds CSS class when provided" do
      result = helper.codex_linkify("See [[XERAEN]]", css_class: "codex-link")
      expect(result).to include('class="codex-link"')
    end

    it "escapes HTML in entry names" do
      result = helper.codex_linkify("See [[<script>alert('xss')</script>]]")
      expect(result).not_to include("<script>")
      expect(result).to include("&lt;script&gt;")
    end

    it "escapes HTML in CSS class" do
      result = helper.codex_linkify("See [[XERAEN]]", css_class: "\" onclick=\"alert('xss')\"")
      # The class attribute value should be HTML-escaped
      expect(result).to include('class="&quot; onclick=&quot;alert')
      # Should not contain an actual executable onclick attribute
      expect(result).not_to match(/class="[^"]*"\s+onclick=/)
    end

    it "returns html_safe string" do
      result = helper.codex_linkify("See [[XERAEN]]")
      expect(result).to be_html_safe
    end

    it "returns empty string for nil" do
      expect(helper.codex_linkify(nil)).to eq("")
    end

    it "returns empty string for blank string" do
      expect(helper.codex_linkify("")).to eq("")
    end

    it "preserves text without links" do
      result = helper.codex_linkify("No links here")
      expect(result).to eq("No links here")
    end

    it "converts [[Entry|custom text]] to HTML link with custom display text" do
      result = helper.codex_linkify("See [[XERAEN|the legendary hackr]] for details")
      expect(result).to include('<a href="/codex/xeraen">the legendary hackr</a>')
    end

    it "handles multiple links with custom text" do
      result = helper.codex_linkify("[[XERAEN|the hackr]] works with [[The Fracture Network|the network]]")
      expect(result).to include('<a href="/codex/xeraen">the hackr</a>')
      expect(result).to include('<a href="/codex/the-fracture-network">the network</a>')
    end

    it "handles mix of standard and custom text links" do
      result = helper.codex_linkify("[[XERAEN|custom text]] and [[The Fracture Network]]")
      expect(result).to include('<a href="/codex/xeraen">custom text</a>')
      expect(result).to include('<a href="/codex/the-fracture-network">The Fracture Network</a>')
    end

    it "escapes HTML in custom text" do
      result = helper.codex_linkify("See [[XERAEN|<script>alert('xss')</script>]]")
      expect(result).not_to include("<script>")
      expect(result).to include("&lt;script&gt;")
    end

    it "adds CSS class to links with custom text" do
      result = helper.codex_linkify("See [[XERAEN|custom]]", css_class: "codex-link")
      expect(result).to include('class="codex-link"')
      expect(result).to include(">custom</a>")
    end
  end

  describe "#markdown_codex_links" do
    it "converts [[Entry Name]] to markdown link" do
      result = helper.markdown_codex_links("See [[XERAEN]] for details")
      expect(result).to eq("See [XERAEN](/codex/xeraen) for details")
    end

    it "handles multiple links" do
      result = helper.markdown_codex_links("[[XERAEN]] and [[The Fracture Network]]")
      expect(result).to eq("[XERAEN](/codex/xeraen) and [The Fracture Network](/codex/the-fracture-network)")
    end

    it "returns empty string for nil" do
      expect(helper.markdown_codex_links(nil)).to eq("")
    end

    it "returns empty string for blank string" do
      expect(helper.markdown_codex_links("")).to eq("")
    end

    it "preserves text without links" do
      result = helper.markdown_codex_links("No links here")
      expect(result).to eq("No links here")
    end

    it "converts [[Entry|custom text]] to markdown link with custom display text" do
      result = helper.markdown_codex_links("See [[XERAEN|the legendary hackr]] for details")
      expect(result).to eq("See [the legendary hackr](/codex/xeraen) for details")
    end

    it "handles multiple links with custom text" do
      result = helper.markdown_codex_links("[[XERAEN|the hackr]] and [[The Fracture Network|the network]]")
      expect(result).to eq("[the hackr](/codex/xeraen) and [the network](/codex/the-fracture-network)")
    end

    it "handles mix of standard and custom text links" do
      result = helper.markdown_codex_links("[[XERAEN|custom text]] and [[The Fracture Network]]")
      expect(result).to eq("[custom text](/codex/xeraen) and [The Fracture Network](/codex/the-fracture-network)")
    end
  end

  describe "#extract_codex_references" do
    it "extracts single reference" do
      result = helper.extract_codex_references("See [[XERAEN]]")
      expect(result).to eq(["XERAEN"])
    end

    it "extracts multiple references" do
      result = helper.extract_codex_references("[[XERAEN]] works with [[The Fracture Network]]")
      expect(result).to contain_exactly("XERAEN", "The Fracture Network")
    end

    it "deduplicates references" do
      result = helper.extract_codex_references("[[XERAEN]] and [[XERAEN]] again")
      expect(result).to eq(["XERAEN"])
    end

    it "returns empty array for nil" do
      expect(helper.extract_codex_references(nil)).to eq([])
    end

    it "returns empty array for blank string" do
      expect(helper.extract_codex_references("")).to eq([])
    end

    it "returns empty array for text without references" do
      result = helper.extract_codex_references("No references here")
      expect(result).to eq([])
    end
  end

  describe "#has_codex_links?" do
    it "returns true when links present" do
      expect(helper.has_codex_links?("See [[XERAEN]]")).to be true
    end

    it "returns false when no links" do
      expect(helper.has_codex_links?("No links here")).to be false
    end

    it "returns false for nil" do
      expect(helper.has_codex_links?(nil)).to be false
    end

    it "returns false for blank string" do
      expect(helper.has_codex_links?("")).to be false
    end

    it "returns true for multiple links" do
      expect(helper.has_codex_links?("[[XERAEN]] and [[The Fracture Network]]")).to be true
    end
  end
end
