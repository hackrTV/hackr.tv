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
class GridDenInvite < ApplicationRecord
  has_paper_trail

  belongs_to :hackr, class_name: "GridHackr"
  belongs_to :guest, class_name: "GridHackr"
  belongs_to :den, class_name: "GridRoom"

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }
  scope :for_guest, ->(guest) { where(guest: guest) }

  def active?
    revoked_at.nil? && expires_at > Time.current
  end

  def revoke!
    update!(revoked_at: Time.current)
  end
end
