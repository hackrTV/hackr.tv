require "rails_helper"

RSpec.describe TestGuide do
  describe ".articles" do
    it "parses every docs/testing article with frontmatter" do
      articles = described_class.articles

      expect(articles.size).to be >= 30
      expect(articles.map(&:slug)).to eq(articles.map(&:slug).uniq)
      articles.each do |article|
        expect(article.title).to be_present, "#{article.slug} missing title"
        expect(article.area).to be_present, "#{article.slug} missing area"
        expect(article.minutes).to be > 0, "#{article.slug} missing minutes"
      end
    end

    it "orders by filename number" do
      slugs = described_class.articles.map(&:slug)
      expect(slugs.first).to eq("00_using_this_guide")
      expect(slugs).to eq(slugs.sort)
    end
  end

  describe ".find" do
    it "resolves a known slug and rejects unknown ones" do
      expect(described_class.find("36_breach").title).to eq("BREACH")
      expect(described_class.find("nope")).to be_nil
      expect(described_class.find("../../config/secrets")).to be_nil
    end
  end

  describe ".neighbors" do
    it "returns prev/next in order, nil at the edges" do
      first = described_class.articles.first
      last = described_class.articles.last

      expect(described_class.neighbors(first.slug).first).to be_nil
      expect(described_class.neighbors(last.slug).last).to be_nil

      prev_article, next_article = described_class.neighbors("36_breach")
      expect(prev_article.slug).to eq("35_tactical_panels")
      expect(next_article.slug).to eq("37_grid_meta_pages")
    end
  end

  describe "#body_html" do
    it "renders markdown and tags ordered-list steps for the checkbox JS" do
      html = described_class.find("02_cross_cutting_invariants").body_html

      expect(html).to include("<h1>")
      expect(html).to include('class="tg-step"')
      expect(html).to include('data-step="02_cross_cutting_invariants:0"')
    end
  end
end
