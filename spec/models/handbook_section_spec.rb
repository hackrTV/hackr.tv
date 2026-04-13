# == Schema Information
#
# Table name: handbook_sections
# Database name: primary
#
#  id         :integer          not null, primary key
#  icon       :string
#  name       :string           not null
#  position   :integer          default(0), not null
#  published  :boolean          default(TRUE), not null
#  slug       :string           not null
#  summary    :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_handbook_sections_on_published               (published)
#  index_handbook_sections_on_published_and_position  (published,position)
#  index_handbook_sections_on_slug                    (slug) UNIQUE
#
require "rails_helper"

RSpec.describe HandbookSection, type: :model do
  describe "validations" do
    it "requires a name" do
      section = build(:handbook_section, name: nil)
      expect(section).not_to be_valid
      expect(section.errors[:name]).to be_present
    end

    it "requires a unique slug" do
      create(:handbook_section, slug: "getting-started")
      duplicate = build(:handbook_section, slug: "getting-started")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:slug]).to be_present
    end

    it "rejects slugs with invalid characters" do
      section = build(:handbook_section, slug: "Has Spaces")
      expect(section).not_to be_valid
      expect(section.errors[:slug]).to be_present
    end

    it "auto-generates a slug from the name when blank" do
      section = build(:handbook_section, name: "Getting Started", slug: nil)
      section.valid?
      expect(section.slug).to eq("getting-started")
    end

    it "rejects negative positions" do
      section = build(:handbook_section, position: -1)
      expect(section).not_to be_valid
    end
  end

  describe "scopes" do
    let!(:published_b) { create(:handbook_section, name: "Bravo", position: 1) }
    let!(:published_a) { create(:handbook_section, name: "Alpha", position: 0) }
    let!(:hidden) { create(:handbook_section, :unpublished, name: "Hidden", position: 2) }

    it ".published returns only published sections" do
      expect(HandbookSection.published).to match_array([published_a, published_b])
    end

    it ".ordered sorts by position then name" do
      expect(HandbookSection.ordered).to eq([published_a, published_b, hidden])
    end
  end

  describe "#to_param" do
    it "returns the slug" do
      section = build(:handbook_section, slug: "pulse-grid")
      expect(section.to_param).to eq("pulse-grid")
    end
  end

  describe "article association" do
    it "destroys dependent articles when the section is destroyed" do
      section = create(:handbook_section)
      create(:handbook_article, handbook_section: section)
      expect { section.destroy }.to change(HandbookArticle, :count).by(-1)
    end
  end
end
