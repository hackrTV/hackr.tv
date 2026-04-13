# == Schema Information
#
# Table name: handbook_articles
# Database name: primary
#
#  id                  :integer          not null, primary key
#  body                :text
#  difficulty          :string
#  kind                :string           default("reference"), not null
#  metadata            :json
#  position            :integer          default(0), not null
#  published           :boolean          default(TRUE), not null
#  slug                :string           not null
#  summary             :text
#  title               :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  handbook_section_id :integer          not null
#
# Indexes
#
#  index_handbook_articles_on_handbook_section_id               (handbook_section_id)
#  index_handbook_articles_on_handbook_section_id_and_position  (handbook_section_id,position)
#  index_handbook_articles_on_kind                              (kind)
#  index_handbook_articles_on_published                         (published)
#  index_handbook_articles_on_slug                              (slug) UNIQUE
#
# Foreign Keys
#
#  handbook_section_id  (handbook_section_id => handbook_sections.id)
#
require "rails_helper"

RSpec.describe HandbookArticle, type: :model do
  describe "validations" do
    it "requires a title" do
      article = build(:handbook_article, title: nil)
      expect(article).not_to be_valid
    end

    it "requires a unique slug globally" do
      create(:handbook_article, slug: "foo")
      duplicate = build(:handbook_article, slug: "foo")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:slug]).to be_present
    end

    it "auto-generates a slug from the title when blank" do
      article = build(:handbook_article, title: "Mine Your First CRED", slug: nil)
      article.valid?
      expect(article.slug).to eq("mine-your-first-cred")
    end

    it "restricts kind to the allowed set" do
      article = build(:handbook_article, kind: "whatever")
      expect(article).not_to be_valid
      expect(article.errors[:kind]).to be_present
    end

    it "allows a blank difficulty" do
      article = build(:handbook_article, difficulty: nil)
      expect(article).to be_valid
    end

    it "restricts difficulty to the allowed set when present" do
      article = build(:handbook_article, difficulty: "impossible")
      expect(article).not_to be_valid
      expect(article.errors[:difficulty]).to be_present
    end

    it "requires a handbook_section" do
      article = build(:handbook_article, handbook_section: nil)
      expect(article).not_to be_valid
    end
  end

  describe "scopes" do
    let(:section) { create(:handbook_section) }
    let!(:published_ref) { create(:handbook_article, handbook_section: section, kind: "reference", position: 0) }
    let!(:published_tut) { create(:handbook_article, :tutorial, handbook_section: section, position: 1) }
    let!(:hidden) { create(:handbook_article, :unpublished, handbook_section: section, position: 2) }

    it ".published filters unpublished" do
      expect(HandbookArticle.published).to match_array([published_ref, published_tut])
    end

    it ".tutorials returns only tutorials" do
      expect(HandbookArticle.tutorials).to eq([published_tut])
    end

    it ".reference_kind returns only reference articles" do
      expect(HandbookArticle.reference_kind).to match_array([published_ref, hidden])
    end

    it ".recently_updated orders by updated_at desc" do
      hidden.touch
      expect(HandbookArticle.recently_updated.first).to eq(hidden)
    end
  end
end
