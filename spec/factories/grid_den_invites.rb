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
FactoryBot.define do
  factory :grid_den_invite do
    association :hackr, factory: :grid_hackr
    association :guest, factory: :grid_hackr
    association :den, factory: [:grid_room, :den]
    expires_at { 1.hour.from_now }
    revoked_at { nil }
  end
end
