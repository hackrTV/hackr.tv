# frozen_string_literal: true

# == Schema Information
#
# Table name: grid_den_invites
# Database name: primary
#
#  id         :integer          not null, primary key
#  expires_at :datetime         not null
#  revoked_at :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  den_id     :integer          not null
#  guest_id   :integer          not null
#  hackr_id   :integer          not null
#
# Indexes
#
#  index_den_invites_unique              (hackr_id,guest_id,den_id) UNIQUE
#  index_grid_den_invites_on_den_id      (den_id)
#  index_grid_den_invites_on_expires_at  (expires_at)
#  index_grid_den_invites_on_guest_id    (guest_id)
#
# Foreign Keys
#
#  den_id    (den_id => grid_rooms.id)
#  guest_id  (guest_id => grid_hackrs.id)
#  hackr_id  (hackr_id => grid_hackrs.id)
#
require "rails_helper"

RSpec.describe GridDenInvite do
  let(:owner) { create(:grid_hackr) }
  let(:guest) { create(:grid_hackr) }
  let(:zone) { create(:grid_zone, :residential) }
  let(:den) { create(:grid_room, :den, grid_zone: zone, owner: owner) }

  describe "associations" do
    it "belongs to hackr (owner)" do
      invite = create(:grid_den_invite, hackr: owner, guest: guest, den: den)
      expect(invite.hackr).to eq(owner)
    end

    it "belongs to guest" do
      invite = create(:grid_den_invite, hackr: owner, guest: guest, den: den)
      expect(invite.guest).to eq(guest)
    end
  end

  describe ".active scope" do
    it "includes non-revoked, non-expired invites" do
      invite = create(:grid_den_invite, hackr: owner, guest: guest, den: den, expires_at: 1.hour.from_now)
      expect(described_class.active).to include(invite)
    end

    it "excludes revoked invites" do
      invite = create(:grid_den_invite, hackr: owner, guest: guest, den: den,
        expires_at: 1.hour.from_now, revoked_at: Time.current)
      expect(described_class.active).not_to include(invite)
    end

    it "excludes expired invites" do
      invite = create(:grid_den_invite, hackr: owner, guest: guest, den: den,
        expires_at: 1.hour.ago)
      expect(described_class.active).not_to include(invite)
    end
  end

  describe "#active?" do
    it "returns true for valid invite" do
      invite = build(:grid_den_invite, expires_at: 1.hour.from_now, revoked_at: nil)
      expect(invite).to be_active
    end

    it "returns false when revoked" do
      invite = build(:grid_den_invite, expires_at: 1.hour.from_now, revoked_at: Time.current)
      expect(invite).not_to be_active
    end

    it "returns false when expired" do
      invite = build(:grid_den_invite, expires_at: 1.hour.ago, revoked_at: nil)
      expect(invite).not_to be_active
    end
  end

  describe "#revoke!" do
    it "sets revoked_at to current time" do
      invite = create(:grid_den_invite, hackr: owner, guest: guest, den: den)
      invite.revoke!
      expect(invite.revoked_at).to be_within(2.seconds).of(Time.current)
      expect(invite).not_to be_active
    end
  end
end
