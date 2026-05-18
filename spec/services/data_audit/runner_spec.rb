# frozen_string_literal: true

require "rails_helper"

RSpec.describe DataAudit::Runner do
  include ActiveSupport::Testing::TimeHelpers

  let(:region) { create(:grid_region) }
  let(:zone) { create(:grid_zone, grid_region: region) }

  # Create a room with no exits — guaranteed to trigger RoomNoExits check
  let!(:room_without_exits) { create(:grid_room, :standard, grid_zone: zone, description: "sealed") }

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

  describe ".run!" do
    it "creates flags for violations found by checks" do
      expect { DataAudit::Runner.run! }.to change(DataAuditFlag, :count).by_at_least(1)
    end

    it "is idempotent — second run does not duplicate flags" do
      DataAudit::Runner.run!
      count_after_first = DataAuditFlag.count
      DataAudit::Runner.run!
      expect(DataAuditFlag.count).to eq(count_after_first)
    end

    it "records scan timestamp" do
      # Use memory store to ensure cache works in test
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      DataAudit::Runner.run!
      expect(DataAudit::FlagCache.last_scan_at).to be_within(5.seconds).of(Time.current)
    end

    it "invalidates the open count cache" do
      cache = ActiveSupport::Cache::MemoryStore.new
      allow(Rails).to receive(:cache).and_return(cache)
      cache.write(DataAudit::FlagCache::OPEN_COUNT_KEY, 999)
      DataAudit::Runner.run!
      expect(cache.read(DataAudit::FlagCache::OPEN_COUNT_KEY)).to be_nil
    end
  end

  describe "reconciliation" do
    it "auto-clears flags when violations are resolved" do
      DataAudit::Runner.run!
      flag = DataAuditFlag.find_by(check_name: "room_no_exits", subject_id: room_without_exits.id)
      expect(flag).to be_present

      # Fix the violation: add an exit
      target = create(:grid_room, grid_zone: zone)
      create(:grid_exit, from_room: room_without_exits, to_room: target, direction: "north")

      DataAudit::Runner.run!
      expect(DataAuditFlag.find_by(fingerprint: flag.fingerprint)).to be_nil
    end

    it "reopens flags with expired snoozes when violation persists" do
      DataAudit::Runner.run!
      flag = DataAuditFlag.find_by(check_name: "room_no_exits", subject_id: room_without_exits.id)
      flag.acknowledge!(1.second.ago) # Already expired

      DataAudit::Runner.run!
      flag.reload
      expect(flag.status).to eq("open")
      expect(flag.snooze_until).to be_nil
    end

    it "leaves actively snoozed flags alone" do
      DataAudit::Runner.run!
      flag = DataAuditFlag.find_by(check_name: "room_no_exits", subject_id: room_without_exits.id)
      flag.acknowledge!(1.day.from_now)

      DataAudit::Runner.run!
      flag.reload
      expect(flag.status).to eq("acknowledged")
    end

    it "touches last_seen_at on existing open flags" do
      DataAudit::Runner.run!
      flag = DataAuditFlag.find_by(check_name: "room_no_exits", subject_id: room_without_exits.id)
      old_seen = flag.last_seen_at

      travel_to 1.minute.from_now do
        DataAudit::Runner.run!
        flag.reload
        expect(flag.last_seen_at).to be > old_seen
      end
    end
  end
end
