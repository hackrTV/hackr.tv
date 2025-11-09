require "rails_helper"

RSpec.describe HackrLog, type: :model do
  describe "associations" do
    it "belongs to author (GridHackr)" do
      association = HackrLog.reflect_on_association(:author)
      expect(association.macro).to eq(:belongs_to)
      expect(association.class_name).to eq("GridHackr")
    end
  end

  describe "validations" do
    let(:author) { create(:grid_hackr) }

    it "is valid with valid attributes" do
      log = build(:hackr_log, author: author)
      expect(log).to be_valid
    end

    it "is invalid without a title" do
      log = build(:hackr_log, author: author, title: nil)
      expect(log).not_to be_valid
      expect(log.errors[:title]).to include("can't be blank")
    end

    it "is invalid without a slug" do
      log = build(:hackr_log, author: author, slug: nil)
      expect(log).not_to be_valid
      expect(log.errors[:slug]).to include("can't be blank")
    end

    it "is invalid without a body" do
      log = build(:hackr_log, author: author, body: nil)
      expect(log).not_to be_valid
      expect(log.errors[:body]).to include("can't be blank")
    end

    it "requires unique slug" do
      create(:hackr_log, author: author, slug: "unique-slug")
      duplicate = build(:hackr_log, author: author, slug: "unique-slug")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:slug]).to include("has already been taken")
    end
  end

  describe "scopes" do
    let(:author) { create(:grid_hackr) }

    describe ".published" do
      it "returns only published logs" do
        published1 = create(:hackr_log, :published, author: author)
        published2 = create(:hackr_log, :published, author: author)
        create(:hackr_log, author: author, published: false)

        expect(HackrLog.published).to contain_exactly(published1, published2)
      end
    end

    describe ".ordered" do
      it "orders by published_at descending" do
        log1 = create(:hackr_log, :published, author: author, published_at: 2.days.ago)
        log2 = create(:hackr_log, :published, author: author, published_at: 1.day.ago)
        log3 = create(:hackr_log, :published, author: author, published_at: Time.current)

        expect(HackrLog.ordered).to eq([log3, log2, log1])
      end

      it "falls back to created_at if published_at is nil" do
        log1 = create(:hackr_log, author: author, published_at: nil, created_at: 2.days.ago)
        log2 = create(:hackr_log, author: author, published_at: nil, created_at: 1.day.ago)

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
    let(:author) { create(:grid_hackr) }
    let(:log) { create(:hackr_log, author: author, published: false, published_at: nil) }

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
    let(:author) { create(:grid_hackr) }
    let(:log) { create(:hackr_log, :published, author: author) }

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
      author = create(:grid_hackr, :admin)
      log = HackrLog.create!(
        author: author,
        title: "Major Resistance Victory",
        slug: "major-resistance-victory",
        body: "# Victory!\n\nWe have achieved a major breakthrough.",
        published: true,
        published_at: Time.current
      )

      expect(log).to be_persisted
      expect(log.author).to eq(author)
      expect(log.published).to be true
      expect(log.published_at).to be_present
    end
  end
end
