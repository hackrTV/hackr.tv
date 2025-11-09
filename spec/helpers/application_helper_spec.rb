require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#markdown" do
    it "converts markdown to HTML" do
      markdown_text = "# Heading\n\nParagraph text."
      result = helper.markdown(markdown_text)
      expect(result).to include("<h1>Heading</h1>")
      expect(result).to include("<p>Paragraph text.</p>")
    end

    it "converts bold text" do
      markdown_text = "**Bold text**"
      result = helper.markdown(markdown_text)
      expect(result).to include("<strong>Bold text</strong>")
    end

    it "converts italic text" do
      markdown_text = "*Italic text*"
      result = helper.markdown(markdown_text)
      expect(result).to include("<em>Italic text</em>")
    end

    it "converts links" do
      markdown_text = "[Link text](https://example.com)"
      result = helper.markdown(markdown_text)
      expect(result).to include('<a href="https://example.com"')
      expect(result).to include("Link text")
    end

    it "converts unordered lists" do
      markdown_text = "- Item 1\n- Item 2"
      result = helper.markdown(markdown_text)
      expect(result).to include("<ul>")
      expect(result).to include("<li>Item 1</li>")
      expect(result).to include("<li>Item 2</li>")
    end

    it "converts fenced code blocks" do
      markdown_text = "```\ncode here\n```"
      result = helper.markdown(markdown_text)
      expect(result).to include("<code>")
    end

    it "converts strikethrough" do
      markdown_text = "~~strikethrough~~"
      result = helper.markdown(markdown_text)
      expect(result).to include("<del>strikethrough</del>")
    end

    it "returns empty string for nil text" do
      result = helper.markdown(nil)
      expect(result).to eq("")
    end

    it "returns empty string for blank text" do
      result = helper.markdown("")
      expect(result).to eq("")
    end

    it "returns html_safe string" do
      result = helper.markdown("# Test")
      expect(result).to be_html_safe
    end

    it "sets external links to open in new tab" do
      markdown_text = "[Link](https://example.com)"
      result = helper.markdown(markdown_text)
      expect(result).to include('target="_blank"')
      expect(result).to include('rel="nofollow"')
    end
  end

  describe "#markdown_excerpt" do
    it "renders markdown and truncates to specified length" do
      markdown_text = "**Bold** text that is very long and should be truncated at some point"
      result = helper.markdown_excerpt(markdown_text, length: 30)
      expect(result.length).to be <= 33 # 30 + "..."
      expect(result).to include("...")
    end

    it "strips HTML tags from rendered markdown" do
      markdown_text = "# Heading\n\nParagraph text."
      result = helper.markdown_excerpt(markdown_text, length: 50)
      expect(result).not_to include("<h1>")
      expect(result).not_to include("<p>")
      expect(result).to include("Heading")
      expect(result).to include("Paragraph")
    end

    it "defaults to 300 character length" do
      long_text = "a" * 400
      result = helper.markdown_excerpt(long_text)
      expect(result.length).to be <= 303 # 300 + "..."
    end

    it "returns empty string for nil text" do
      result = helper.markdown_excerpt(nil)
      expect(result).to eq("")
    end

    it "returns empty string for blank text" do
      result = helper.markdown_excerpt("")
      expect(result).to eq("")
    end

    it "does not truncate short text" do
      short_text = "Short text"
      result = helper.markdown_excerpt(short_text, length: 50)
      expect(result.strip).to eq("Short text")
      expect(result).not_to include("...")
    end
  end

  describe "#future_date" do
    it "adds 100 years to a date" do
      date = Date.new(2025, 1, 8)
      result = helper.future_date(date)
      expect(result).to eq(Date.new(2125, 1, 8))
    end

    it "adds 100 years to a datetime" do
      datetime = Time.zone.parse("2025-01-08 14:30:00")
      result = helper.future_date(datetime)
      expect(result.year).to eq(2125)
      expect(result.month).to eq(1)
      expect(result.day).to eq(8)
      expect(result.hour).to eq(14)
      expect(result.min).to eq(30)
    end

    it "returns nil for nil date" do
      result = helper.future_date(nil)
      expect(result).to be_nil
    end

    it "handles leap years correctly" do
      # 2024 is a leap year, 2124 should also be a leap year
      date = Date.new(2024, 2, 29)
      result = helper.future_date(date)
      expect(result).to eq(Date.new(2124, 2, 29))
    end
  end
end
