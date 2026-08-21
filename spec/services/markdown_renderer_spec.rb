require "rails_helper"

RSpec.describe MarkdownRenderer do
  describe ".render_user" do
    it "renders basic markdown" do
      html = described_class.render_user("**bold** and _italic_")
      expect(html).to include("<strong>bold</strong>")
      expect(html).to include("<em>italic</em>")
    end

    it "renders GFM extensions (tables, strikethrough, fenced code)" do
      html = described_class.render_user("| a | b |\n|---|---|\n| 1 | 2 |")
      expect(html).to include("<table>")

      expect(described_class.render_user("~~gone~~")).to include("<del>gone</del>")
      expect(described_class.render_user("```\ncode\n```")).to include("<pre><code>")
    end

    it "autolinks bare URLs with nofollow" do
      html = described_class.render_user("see https://example.com now")
      expect(html).to include('href="https://example.com"')
      expect(html).to include("nofollow")
    end

    it "strips script tags and event handlers" do
      html = described_class.render_user("hi <script>alert(1)</script> <b onmouseover=\"alert(1)\">x</b>")
      expect(html).not_to include("<script")
      expect(html).not_to include("alert(1)</script>")
      expect(html).not_to include("onmouseover")
      expect(html).to include("<b>x</b>")
    end

    it "strips disallowed tags but keeps their text" do
      html = described_class.render_user("a <iframe src='https://evil.example'></iframe> b")
      expect(html).not_to include("<iframe")
    end

    it "returns an empty string for blank input" do
      expect(described_class.render_user(nil)).to eq("")
      expect(described_class.render_user("")).to eq("")
    end

    it "returns html_safe output" do
      expect(described_class.render_user("hello")).to be_html_safe
    end
  end

  describe ".render_trusted" do
    it "passes raw HTML through" do
      html = described_class.render_trusted("before <div class=\"custom\">kept</div> after")
      expect(html).to include('<div class="custom">kept</div>')
    end

    it "returns an empty string for blank input" do
      expect(described_class.render_trusted(nil)).to eq("")
    end
  end
end
