# == Schema Information
#
# Table name: grid_messages
# Database name: primary
#
#  id              :integer          not null, primary key
#  content         :text
#  message_type    :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  grid_hackr_id   :integer
#  room_id         :integer
#  target_hackr_id :integer
#
class GridMessage < ApplicationRecord
  include ProfanityFilterable

  belongs_to :grid_hackr
  belongs_to :room, class_name: "GridRoom", optional: true
  belongs_to :target_hackr, class_name: "GridHackr", optional: true

  validates :content, presence: true
  validates :message_type, inclusion: {in: %w[say whisper broadcast system]}
  filter_profanity :content

  scope :recent, -> { order(created_at: :desc).limit(50) }
  scope :in_room, ->(room) { where(room: room, message_type: "say") }
end
