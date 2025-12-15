require "rails_helper"

RSpec.describe GridHackr, type: :model do
  let(:zone) { create(:grid_zone) }
  let(:room) { create(:grid_room, grid_zone: zone) }

  describe "validations" do
    it "requires a hackr_alias" do
      hackr = build(:grid_hackr, hackr_alias: nil)
      expect(hackr).not_to be_valid
      expect(hackr.errors[:hackr_alias]).to include("can't be blank")
    end

    it "requires a unique hackr_alias" do
      create(:grid_hackr, hackr_alias: "XERAEN")
      duplicate = build(:grid_hackr, hackr_alias: "XERAEN")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:hackr_alias]).to include("has already been taken")
    end

    it "requires a valid role" do
      hackr = build(:grid_hackr, role: "invalid_role")
      expect(hackr).not_to be_valid
      expect(hackr.errors[:role]).to include("invalid_role is not a valid role")
    end

    it "accepts 'operative' role" do
      hackr = build(:grid_hackr, role: "operative")
      expect(hackr).to be_valid
    end

    it "accepts 'admin' role" do
      hackr = build(:grid_hackr, role: "admin")
      expect(hackr).to be_valid
    end
  end

  describe "associations" do
    it { should belong_to(:current_room).class_name("GridRoom").optional }
    it { should have_many(:grid_items) }
    it { should have_many(:grid_messages) }
  end

  describe "default values" do
    it "defaults role to 'operative'" do
      hackr = GridHackr.new(hackr_alias: "TestHackr", password: "password123")
      expect(hackr.role).to eq("operative")
    end

    it "does not override explicitly set role" do
      hackr = GridHackr.new(hackr_alias: "AdminHackr", password: "password123", role: "admin")
      expect(hackr.role).to eq("admin")
    end
  end

  describe "authentication" do
    let(:hackr) { create(:grid_hackr, password: "hackthegrid") }

    it "authenticates with correct password" do
      expect(hackr.authenticate("hackthegrid")).to eq(hackr)
    end

    it "returns false with incorrect password" do
      expect(hackr.authenticate("wrongpassword")).to be_falsey
    end

    it "stores password_digest, not plaintext password" do
      expect(hackr.password_digest).to be_present
      expect(hackr.password_digest).not_to eq("hackthegrid")
    end
  end

  describe "scopes" do
    let!(:admin1) { create(:grid_hackr, role: "admin") }
    let!(:admin2) { create(:grid_hackr, role: "admin") }
    let!(:operative1) { create(:grid_hackr, role: "operative") }
    let!(:operative2) { create(:grid_hackr, role: "operative") }
    let!(:online_hackr) { create(:grid_hackr, current_room: room) }
    let!(:offline_hackr) { create(:grid_hackr, current_room: nil) }

    describe ".admins" do
      it "returns only admin hackrs" do
        expect(GridHackr.admins).to match_array([admin1, admin2])
      end
    end

    describe ".operatives" do
      it "returns only operative hackrs" do
        expect(GridHackr.operatives).to include(operative1, operative2)
      end
    end

    describe ".online" do
      it "returns hackrs with a current_room and recent activity" do
        online_hackr.update_column(:last_activity_at, 5.minutes.ago)
        expect(GridHackr.online).to include(online_hackr)
        expect(GridHackr.online).not_to include(offline_hackr)
      end

      it "excludes hackrs with stale activity even if they have a room" do
        stale_hackr = create(:grid_hackr, current_room: room)
        stale_hackr.update_column(:last_activity_at, 20.minutes.ago)
        expect(GridHackr.online).not_to include(stale_hackr)
      end
    end

    describe ".in_room" do
      it "returns hackrs in the specified room" do
        expect(GridHackr.in_room(room)).to include(online_hackr)
        expect(GridHackr.in_room(room)).not_to include(offline_hackr)
      end
    end

    describe ".recently_active" do
      it "returns hackrs with activity within the specified time" do
        active_hackr = create(:grid_hackr)
        active_hackr.update_column(:last_activity_at, 5.minutes.ago)

        inactive_hackr = create(:grid_hackr)
        inactive_hackr.update_column(:last_activity_at, 20.minutes.ago)

        expect(GridHackr.recently_active(since: 10.minutes.ago)).to include(active_hackr)
        expect(GridHackr.recently_active(since: 10.minutes.ago)).not_to include(inactive_hackr)
      end

      it "defaults to 15 minutes ago" do
        recent_hackr = create(:grid_hackr)
        recent_hackr.update_column(:last_activity_at, 10.minutes.ago)

        old_hackr = create(:grid_hackr)
        old_hackr.update_column(:last_activity_at, 20.minutes.ago)

        expect(GridHackr.recently_active).to include(recent_hackr)
        expect(GridHackr.recently_active).not_to include(old_hackr)
      end
    end
  end

  describe "role checks" do
    let(:admin) { create(:grid_hackr, role: "admin") }
    let(:operative) { create(:grid_hackr, role: "operative") }

    describe "#admin?" do
      it "returns true for admin role" do
        expect(admin.admin?).to be true
      end

      it "returns false for operative role" do
        expect(operative.admin?).to be false
      end
    end

    describe "#operative?" do
      it "returns true for operative role" do
        expect(operative.operative?).to be true
      end

      it "returns false for admin role" do
        expect(admin.operative?).to be false
      end
    end
  end

  describe "#touch_activity!" do
    it "updates last_activity_at timestamp" do
      hackr = create(:grid_hackr)
      hackr.update_column(:last_activity_at, 1.hour.ago)

      expect {
        hackr.touch_activity!
      }.to change { hackr.reload.last_activity_at }
    end

    it "sets last_activity_at to current time" do
      hackr = create(:grid_hackr)
      hackr.touch_activity!
      expect(hackr.reload.last_activity_at).to be_within(1.second).of(Time.current)
    end
  end
end
