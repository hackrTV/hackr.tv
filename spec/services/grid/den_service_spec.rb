# frozen_string_literal: true

require "rails_helper"

RSpec.describe Grid::DenService do
  let(:zone) { create(:grid_zone, :residential, slug: "residential-district") }
  let(:corridor) { create(:grid_room, :hub, grid_zone: zone, slug: "residential-corridor", name: "Residential Corridor") }
  let(:hackr) { create(:grid_hackr) }
  let(:service) { described_class.new(hackr) }

  before { corridor } # ensure corridor exists

  describe "#create_den!" do
    it "creates a den room in the residential zone" do
      den = service.create_den!

      expect(den).to be_persisted
      expect(den.room_type).to eq("den")
      expect(den.owner).to eq(hackr)
      expect(den.grid_zone).to eq(zone)
      expect(den.name).to eq("#{hackr.hackr_alias}'s Den")
      expect(den.slug).to start_with("den-")
    end

    it "creates bidirectional exits" do
      den = service.create_den!

      corridor_to_den = corridor.exits_from.find_by(to_room: den)
      expect(corridor_to_den).to be_present
      expect(corridor_to_den.direction).to eq(den.slug)

      den_to_corridor = den.exits_from.find_by(to_room: corridor)
      expect(den_to_corridor).to be_present
      expect(den_to_corridor.direction).to eq("out")
    end

    it "raises DenAlreadyExists if hackr already has a den" do
      service.create_den!

      expect { service.create_den! }.to raise_error(described_class::DenAlreadyExists)
    end
  end

  describe "#rename_den!" do
    let!(:den) { service.create_den! }

    it "renames the den" do
      service.rename_den!("XERAEN's Lair")
      expect(den.reload.name).to eq("XERAEN's Lair")
    end

    it "raises DenNotFound when hackr has no den" do
      other = described_class.new(create(:grid_hackr))
      expect { other.rename_den!("Nope") }.to raise_error(described_class::DenNotFound)
    end

    it "rejects names over 80 characters via validation" do
      den.update!(name: "x" * 80)
      expect(den).to be_valid

      expect {
        den.update!(name: "x" * 81)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "#describe_den!" do
    let!(:den) { service.create_den! }

    it "updates the den description" do
      service.describe_den!("A cozy digital space.")
      expect(den.reload.description).to eq("A cozy digital space.")
    end
  end

  describe "#invite!" do
    let!(:den) { service.create_den! }
    let(:guest) { create(:grid_hackr) }

    it "creates an invite with 1 hour expiry" do
      invite = service.invite!(guest.hackr_alias)

      expect(invite).to be_persisted
      expect(invite.hackr).to eq(hackr)
      expect(invite.guest).to eq(guest)
      expect(invite.den).to eq(den)
      expect(invite.expires_at).to be_within(5.seconds).of(1.hour.from_now)
      expect(invite).to be_active
    end

    it "extends an existing invite (upserts same record)" do
      first_invite = service.invite!(guest.hackr_alias)
      first_id = first_invite.id
      first_expires = first_invite.expires_at

      # Re-invite resets the expiry on the same record
      extended = service.invite!(guest.hackr_alias)
      expect(extended.id).to eq(first_id)
      expect(extended.expires_at).to be >= first_expires
    end

    it "reactivates a revoked invite" do
      invite = service.invite!(guest.hackr_alias)
      invite.revoke!
      expect(invite.reload).not_to be_active

      reactivated = service.invite!(guest.hackr_alias)
      expect(reactivated).to be_active
      expect(reactivated.revoked_at).to be_nil
    end
  end

  describe "#uninvite!" do
    let!(:den) { service.create_den! }
    let(:guest) { create(:grid_hackr) }

    it "revokes all active invites for a guest" do
      invite = service.invite!(guest.hackr_alias)
      service.uninvite!(guest.hackr_alias)

      expect(invite.reload).not_to be_active
      expect(invite.revoked_at).to be_present
    end
  end

  describe "#lock_den! / #unlock_den!" do
    let!(:den) { service.create_den! }

    it "locks the den when in the den" do
      service.lock_den!(den)
      expect(den.reload).to be_locked
    end

    it "locks the den when in the corridor" do
      service.lock_den!(corridor)
      expect(den.reload).to be_locked
    end

    it "raises NotInDenOrCorridor from another room" do
      other_room = create(:grid_room, grid_zone: zone)
      expect { service.lock_den!(other_room) }.to raise_error(described_class::NotInDenOrCorridor)
    end

    it "unlocks the den" do
      service.lock_den!(den)
      service.unlock_den!(den)
      expect(den.reload).not_to be_locked
    end
  end

  describe "#can_enter_den?" do
    let!(:den) { service.create_den! }

    it "allows the owner" do
      expect(service.can_enter_den?(den)).to be true
    end

    it "allows an invited guest" do
      guest = create(:grid_hackr)
      service.invite!(guest.hackr_alias)

      guest_service = described_class.new(guest)
      expect(guest_service.can_enter_den?(den)).to be true
    end

    it "blocks an uninvited guest" do
      stranger = create(:grid_hackr)
      stranger_service = described_class.new(stranger)
      expect(stranger_service.can_enter_den?(den)).to be false
    end

    it "blocks a guest with an expired invite" do
      guest = create(:grid_hackr)
      invite = service.invite!(guest.hackr_alias)
      # Manually expire the invite
      invite.update_column(:expires_at, 1.hour.ago)

      guest_service = described_class.new(guest)
      expect(guest_service.can_enter_den?(den)).to be false
    end

    it "blocks a guest with a revoked invite" do
      guest = create(:grid_hackr)
      service.invite!(guest.hackr_alias)
      service.uninvite!(guest.hackr_alias)

      guest_service = described_class.new(guest)
      expect(guest_service.can_enter_den?(den)).to be false
    end
  end
end
