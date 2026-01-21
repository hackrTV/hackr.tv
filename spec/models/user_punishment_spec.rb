require "rails_helper"

RSpec.describe UserPunishment, type: :model do
  describe "validations" do
    it { should validate_presence_of(:punishment_type) }

    it "validates punishment_type is squelch or blackout" do
      punishment = build(:user_punishment, punishment_type: "invalid")
      expect(punishment).not_to be_valid
      expect(punishment.errors[:punishment_type]).to be_present
    end

    it "accepts squelch as punishment_type" do
      punishment = build(:user_punishment, punishment_type: "squelch")
      expect(punishment).to be_valid
    end

    it "accepts blackout as punishment_type" do
      punishment = build(:user_punishment, punishment_type: "blackout")
      expect(punishment).to be_valid
    end
  end

  describe "associations" do
    it { should belong_to(:grid_hackr) }
    it { should belong_to(:issued_by).class_name("GridHackr") }
  end

  describe "scopes" do
    describe ".active" do
      it "returns punishments that are not expired" do
        active_permanent = create(:user_punishment)
        active_temporary = create(:user_punishment, :temporary)
        create(:user_punishment, :expired)

        expect(UserPunishment.active).to contain_exactly(active_permanent, active_temporary)
      end
    end

    describe ".squelches" do
      it "returns only squelch punishments" do
        squelch = create(:user_punishment, :squelch)
        create(:user_punishment, :blackout)

        expect(UserPunishment.squelches).to contain_exactly(squelch)
      end
    end

    describe ".blackouts" do
      it "returns only blackout punishments" do
        create(:user_punishment, :squelch)
        blackout = create(:user_punishment, :blackout)

        expect(UserPunishment.blackouts).to contain_exactly(blackout)
      end
    end
  end

  describe ".squelch!" do
    let(:hackr) { create(:grid_hackr) }
    let(:moderator) { create(:grid_hackr, :operator) }

    it "creates a squelch punishment" do
      punishment = UserPunishment.squelch!(hackr, issued_by: moderator)

      expect(punishment).to be_persisted
      expect(punishment.punishment_type).to eq("squelch")
      expect(punishment.grid_hackr).to eq(hackr)
      expect(punishment.issued_by).to eq(moderator)
    end

    it "sets expires_at when duration_minutes is provided" do
      punishment = UserPunishment.squelch!(hackr, issued_by: moderator, duration_minutes: 30)

      expect(punishment.expires_at).to be_within(1.second).of(30.minutes.from_now)
    end

    it "leaves expires_at nil for permanent squelch" do
      punishment = UserPunishment.squelch!(hackr, issued_by: moderator)

      expect(punishment.expires_at).to be_nil
    end

    it "creates a moderation log entry" do
      expect {
        UserPunishment.squelch!(hackr, issued_by: moderator, reason: "Spam")
      }.to change(ModerationLog, :count).by(1)

      log = ModerationLog.last
      expect(log.action).to eq("squelch")
      expect(log.actor).to eq(moderator)
      expect(log.target).to eq(hackr)
      expect(log.reason).to eq("Spam")
    end
  end

  describe ".blackout!" do
    let(:hackr) { create(:grid_hackr) }
    let(:admin) { create(:grid_hackr, :admin) }

    it "creates a blackout punishment" do
      punishment = UserPunishment.blackout!(hackr, issued_by: admin)

      expect(punishment).to be_persisted
      expect(punishment.punishment_type).to eq("blackout")
      expect(punishment.grid_hackr).to eq(hackr)
      expect(punishment.issued_by).to eq(admin)
    end

    it "creates a moderation log entry" do
      expect {
        UserPunishment.blackout!(hackr, issued_by: admin, reason: "Harassment")
      }.to change(ModerationLog, :count).by(1)

      log = ModerationLog.last
      expect(log.action).to eq("blackout")
    end
  end

  describe ".squelched?" do
    let(:hackr) { create(:grid_hackr) }

    it "returns true when user has active squelch" do
      create(:user_punishment, :squelch, grid_hackr: hackr)
      expect(UserPunishment.squelched?(hackr)).to be true
    end

    it "returns false when user has no active squelch" do
      expect(UserPunishment.squelched?(hackr)).to be false
    end

    it "returns false when squelch is expired" do
      create(:user_punishment, :squelch, :expired, grid_hackr: hackr)
      expect(UserPunishment.squelched?(hackr)).to be false
    end
  end

  describe ".blackouted?" do
    let(:hackr) { create(:grid_hackr) }

    it "returns true when user has active blackout" do
      create(:user_punishment, :blackout, grid_hackr: hackr)
      expect(UserPunishment.blackouted?(hackr)).to be true
    end

    it "returns false when user has no active blackout" do
      expect(UserPunishment.blackouted?(hackr)).to be false
    end
  end

  describe "#lift!" do
    let(:punishment) { create(:user_punishment) }
    let(:moderator) { create(:grid_hackr, :operator) }

    it "destroys the punishment" do
      punishment.lift!(moderator)

      expect(UserPunishment.exists?(punishment.id)).to be false
    end

    it "creates a moderation log entry" do
      expect {
        punishment.lift!(moderator)
      }.to change(ModerationLog, :count).by(1)

      log = ModerationLog.last
      expect(log.action).to eq("unsquelch")
    end
  end

  describe "#expired?" do
    it "returns true for expired punishment" do
      punishment = create(:user_punishment, :expired)
      expect(punishment.expired?).to be true
    end

    it "returns false for active temporary punishment" do
      punishment = create(:user_punishment, :temporary)
      expect(punishment.expired?).to be false
    end

    it "returns false for permanent punishment" do
      punishment = create(:user_punishment)
      expect(punishment.expired?).to be false
    end
  end

  describe "#permanent?" do
    it "returns true when expires_at is nil" do
      punishment = create(:user_punishment, expires_at: nil)
      expect(punishment.permanent?).to be true
    end

    it "returns false when expires_at is set" do
      punishment = create(:user_punishment, :temporary)
      expect(punishment.permanent?).to be false
    end
  end
end
