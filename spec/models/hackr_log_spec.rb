# == Schema Information
#
# Table name: hackr_logs
# Database name: primary
#
#  id            :integer          not null, primary key
#  body          :text             not null
#  published     :boolean          default(FALSE), not null
#  published_at  :datetime
#  slug          :string           not null
#  title         :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  grid_hackr_id :integer          not null
#
# Indexes
#
#  index_hackr_logs_on_grid_hackr_id  (grid_hackr_id)
#  index_hackr_logs_on_slug           (slug) UNIQUE
#
# Foreign Keys
#
#  grid_hackr_id  (grid_hackr_id => grid_hackrs.id)
#
require "rails_helper"

RSpec.describe HackrLog, type: :model do
  describe "associations" do
    it "belongs to grid_hackr" do
      association = HackrLog.reflect_on_association(:grid_hackr)
      expect(association.macro).to eq(:belongs_to)
      expect(association.class_name).to eq("GridHackr")
    end
  end

  describe "validations" do
    let(:grid_hackr) { create(:grid_hackr) }

    it "is valid with valid attributes" do
      log = build(:hackr_log, grid_hackr: grid_hackr)
      expect(log).to be_valid
    end

    it "is invalid without a title" do
      log = build(:hackr_log, grid_hackr: grid_hackr, title: nil)
      expect(log).not_to be_valid
      expect(log.errors[:title]).to include("can't be blank")
    end

    it "is invalid without a slug" do
      log = build(:hackr_log, grid_hackr: grid_hackr, slug: nil)
      expect(log).not_to be_valid
      expect(log.errors[:slug]).to include("can't be blank")
    end

    it "is invalid without a body" do
      log = build(:hackr_log, grid_hackr: grid_hackr, body: nil)
      expect(log).not_to be_valid
      expect(log.errors[:body]).to include("can't be blank")
    end

    it "requires unique slug" do
      create(:hackr_log, grid_hackr: grid_hackr, slug: "unique-slug")
      duplicate = build(:hackr_log, grid_hackr: grid_hackr, slug: "unique-slug")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:slug]).to include("has already been taken")
    end
  end

  describe "scopes" do
    let(:grid_hackr) { create(:grid_hackr) }

    describe ".published" do
      it "returns only published logs" do
        published1 = create(:hackr_log, :published, grid_hackr: grid_hackr)
        published2 = create(:hackr_log, :published, grid_hackr: grid_hackr)
        create(:hackr_log, grid_hackr: grid_hackr, published: false)

        expect(HackrLog.published).to contain_exactly(published1, published2)
      end
    end

    describe ".ordered" do
      it "orders by published_at descending" do
        log1 = create(:hackr_log, :published, grid_hackr: grid_hackr, published_at: 2.days.ago)
        log2 = create(:hackr_log, :published, grid_hackr: grid_hackr, published_at: 1.day.ago)
        log3 = create(:hackr_log, :published, grid_hackr: grid_hackr, published_at: Time.current)

        expect(HackrLog.ordered).to eq([log3, log2, log1])
      end

      it "falls back to created_at if published_at is nil" do
        log1 = create(:hackr_log, grid_hackr: grid_hackr, published_at: nil, created_at: 2.days.ago)
        log2 = create(:hackr_log, grid_hackr: grid_hackr, published_at: nil, created_at: 1.day.ago)

        expect(HackrLog.ordered).to eq([log2, log1])
      end
    end
  end

  describe "#to_param" do
    it "returns the slug" do
      log = build(:hackr_log, slug: "my-log-slug")
      expect(log.to_param).to eq("my-log-slug")
    end
  end

  describe "#publish!" do
    let(:grid_hackr) { create(:grid_hackr) }
    let(:log) { create(:hackr_log, grid_hackr: grid_hackr, published: false, published_at: nil) }

    it "sets published to true" do
      log.publish!
      expect(log.published).to be true
    end

    it "sets published_at to current time" do
      before_time = Time.current
      log.publish!
      after_time = Time.current
      expect(log.published_at).to be_between(before_time, after_time)
    end

    it "does not change published_at if already published" do
      log.update!(published: true, published_at: 1.week.ago)
      original_time = log.published_at

      log.publish!
      expect(log.published_at).to eq(original_time)
    end
  end

  describe "#unpublish!" do
    let(:grid_hackr) { create(:grid_hackr) }
    let(:log) { create(:hackr_log, :published, grid_hackr: grid_hackr) }

    it "sets published to false" do
      log.unpublish!
      expect(log.published).to be false
    end

    it "does not change published_at" do
      original_time = log.published_at
      log.unpublish!
      expect(log.published_at).to eq(original_time)
    end
  end

  describe "full lifecycle" do
    it "creates a log with all attributes" do
      hackr = create(:grid_hackr, :admin)
      log = HackrLog.create!(
        grid_hackr: hackr,
        title: "Major Resistance Victory",
        slug: "major-resistance-victory",
        body: "# Victory!\n\nWe have achieved a major breakthrough.",
        published: true,
        published_at: Time.current
      )

      expect(log).to be_persisted
      expect(log.grid_hackr).to eq(hackr)
      expect(log.published).to be true
      expect(log.published_at).to be_present
    end
  end
end
