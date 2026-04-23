# frozen_string_literal: true

# == Schema Information
#
# Table name: grid_breach_templates
# Database name: primary
#
#  id                    :integer          not null, primary key
#  base_detection_rate   :integer          default(5), not null
#  cooldown_max          :integer          default(600), not null
#  cooldown_min          :integer          default(300), not null
#  cred_reward           :integer          default(0), not null
#  description           :text
#  min_clearance         :integer          default(0), not null
#  name                  :string           not null
#  pnr_threshold         :integer          default(75), not null
#  position              :integer          default(0), not null
#  protocol_composition  :json             not null
#  published             :boolean          default(FALSE), not null
#  requires_item_slug    :string
#  requires_mission_slug :string
#  reward_table          :json             not null
#  slug                  :string           not null
#  tier                  :string           default("standard"), not null
#  xp_reward             :integer          default(0), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
# Indexes
#
#  index_grid_breach_templates_on_published  (published)
#  index_grid_breach_templates_on_slug       (slug) UNIQUE
#  index_grid_breach_templates_on_tier       (tier)
#
require "rails_helper"

RSpec.describe GridBreachTemplate, type: :model do
  describe "validations" do
    subject { build(:grid_breach_template) }

    it { is_expected.to be_valid }

    it "requires a slug" do
      subject.slug = nil
      expect(subject).not_to be_valid
    end

    it "requires a unique slug" do
      create(:grid_breach_template, slug: "dupe-slug")
      subject.slug = "dupe-slug"
      expect(subject).not_to be_valid
    end

    it "requires a name" do
      subject.name = nil
      expect(subject).not_to be_valid
    end

    it "validates tier inclusion" do
      subject.tier = "invalid"
      expect(subject).not_to be_valid
    end

    it "validates min_clearance is non-negative" do
      subject.min_clearance = -1
      expect(subject).not_to be_valid
    end
  end

  describe "#to_param" do
    it "returns the slug" do
      template = build(:grid_breach_template, slug: "test-breach")
      expect(template.to_param).to eq("test-breach")
    end
  end

  describe "#tier_label" do
    it "returns uppercase tier with underscores replaced" do
      template = build(:grid_breach_template, tier: "world_event")
      expect(template.tier_label).to eq("WORLD EVENT")
    end
  end

  describe "#protocols" do
    it "returns the protocol_composition array" do
      template = build(:grid_breach_template, protocol_composition: [{"type" => "trace", "count" => 1}])
      expect(template.protocols).to eq([{"type" => "trace", "count" => 1}])
    end

    it "returns empty array for non-array composition" do
      template = build(:grid_breach_template, protocol_composition: {})
      expect(template.protocols).to eq([])
    end
  end

  describe "scopes" do
    it "published returns only published templates" do
      create(:grid_breach_template, published: true)
      create(:grid_breach_template, published: false)
      expect(GridBreachTemplate.published.count).to eq(1)
    end
  end
end
