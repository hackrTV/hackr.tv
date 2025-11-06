class GridMessage < ApplicationRecord
  belongs_to :grid_hackr
  belongs_to :room, class_name: "GridRoom", optional: true
  belongs_to :target_hackr, class_name: "GridHackr", optional: true

  validates :content, presence: true
  validates :message_type, inclusion: {in: %w[say whisper broadcast system]}

  scope :recent, -> { order(created_at: :desc).limit(50) }
  scope :in_room, ->(room) { where(room: room, message_type: "say") }
end
