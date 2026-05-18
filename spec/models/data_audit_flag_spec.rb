# frozen_string_literal: true

# == Schema Information
#
# Table name: data_audit_flags
# Database name: primary
#
#  id               :integer          not null, primary key
#  check_name       :string           not null
#  domain           :string           not null
#  fingerprint      :string           not null
#  first_flagged_at :datetime         not null
#  last_seen_at     :datetime         not null
#  severity         :string           default("warning"), not null
#  snooze_until     :datetime
#  status           :string           default("open"), not null
#  subject_type     :string
#  title            :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  subject_id       :integer
#
# Indexes
#
#  index_data_audit_flags_on_check_name                   (check_name)
#  index_data_audit_flags_on_domain                       (domain)
#  index_data_audit_flags_on_fingerprint                  (fingerprint) UNIQUE
#  index_data_audit_flags_on_status_and_severity          (status,severity)
#  index_data_audit_flags_on_subject_type_and_subject_id  (subject_type,subject_id)
#
require "rails_helper"

RSpec.describe DataAuditFlag do
  def create_flag(attrs = {})
    DataAuditFlag.create!({
      fingerprint: SecureRandom.hex(32),
      check_name: "test_check",
      title: "Test flag",
      severity: "warning",
      domain: "grid",
      status: "open",
      first_flagged_at: Time.current,
      last_seen_at: Time.current
    }.merge(attrs))
  end

  describe "validations" do
    it "requires fingerprint, title, check_name" do
      flag = DataAuditFlag.new
      flag.valid?
      expect(flag.errors[:fingerprint]).to be_present
      expect(flag.errors[:title]).to be_present
      expect(flag.errors[:check_name]).to be_present
    end

    it "enforces fingerprint uniqueness" do
      create_flag(fingerprint: "dup")
      dup = DataAuditFlag.new(fingerprint: "dup", check_name: "x", title: "x",
        severity: "warning", domain: "grid", first_flagged_at: Time.current, last_seen_at: Time.current)
      expect(dup).not_to be_valid
      expect(dup.errors[:fingerprint]).to include("has already been taken")
    end

    it "validates severity inclusion" do
      flag = DataAuditFlag.new(severity: "bogus")
      flag.valid?
      expect(flag.errors[:severity]).to be_present
    end

    it "validates domain inclusion" do
      flag = DataAuditFlag.new(domain: "bogus")
      flag.valid?
      expect(flag.errors[:domain]).to be_present
    end

    it "validates status inclusion" do
      flag = DataAuditFlag.new(status: "bogus")
      flag.valid?
      expect(flag.errors[:status]).to be_present
    end
  end

  describe "#effective_status" do
    it "returns open for open flags" do
      flag = create_flag(status: "open")
      expect(flag.effective_status).to eq("open")
    end

    it "returns acknowledged for actively snoozed flags" do
      flag = create_flag(status: "acknowledged", snooze_until: 1.hour.from_now)
      expect(flag.effective_status).to eq("acknowledged")
    end

    it "returns open for expired snooze" do
      flag = create_flag(status: "acknowledged", snooze_until: 1.hour.ago)
      expect(flag.effective_status).to eq("open")
    end

    it "returns acknowledged for forever-snoozed flags (nil snooze_until)" do
      flag = create_flag(status: "acknowledged", snooze_until: nil)
      expect(flag.effective_status).to eq("acknowledged")
    end
  end

  describe "#snooze_expired?" do
    it "false for open flags" do
      expect(create_flag(status: "open").snooze_expired?).to be false
    end

    it "false for actively snoozed" do
      expect(create_flag(status: "acknowledged", snooze_until: 1.day.from_now).snooze_expired?).to be false
    end

    it "true for expired snooze" do
      expect(create_flag(status: "acknowledged", snooze_until: 1.hour.ago).snooze_expired?).to be true
    end

    it "false for forever snooze" do
      expect(create_flag(status: "acknowledged", snooze_until: nil).snooze_expired?).to be false
    end
  end

  describe "#acknowledge!" do
    it "sets status and snooze_until" do
      flag = create_flag
      until_time = 7.days.from_now
      flag.acknowledge!(until_time)
      flag.reload
      expect(flag.status).to eq("acknowledged")
      expect(flag.snooze_until).to be_within(1.second).of(until_time)
    end

    it "supports forever snooze with nil" do
      flag = create_flag
      flag.acknowledge!(nil)
      flag.reload
      expect(flag.status).to eq("acknowledged")
      expect(flag.snooze_until).to be_nil
    end
  end

  describe "#reopen!" do
    it "resets status and clears snooze" do
      flag = create_flag(status: "acknowledged", snooze_until: 1.day.from_now)
      flag.reopen!
      flag.reload
      expect(flag.status).to eq("open")
      expect(flag.snooze_until).to be_nil
    end
  end

  describe ".effective_open scope" do
    it "includes open flags" do
      flag = create_flag(status: "open")
      expect(DataAuditFlag.effective_open).to include(flag)
    end

    it "includes expired snoozes" do
      flag = create_flag(status: "acknowledged", snooze_until: 1.hour.ago)
      expect(DataAuditFlag.effective_open).to include(flag)
    end

    it "excludes actively snoozed flags" do
      flag = create_flag(status: "acknowledged", snooze_until: 1.day.from_now)
      expect(DataAuditFlag.effective_open).not_to include(flag)
    end

    it "excludes forever-snoozed flags" do
      flag = create_flag(status: "acknowledged", snooze_until: nil)
      expect(DataAuditFlag.effective_open).not_to include(flag)
    end
  end
end
