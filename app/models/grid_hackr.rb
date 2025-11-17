class GridHackr < ApplicationRecord
  has_secure_password

  belongs_to :current_room, class_name: "GridRoom", optional: true
  has_many :grid_items
  has_many :grid_messages
  has_many :playlists, dependent: :destroy

  validates :hackr_alias, presence: true, uniqueness: true
  validates :role, inclusion: {in: %w[operative admin], message: "%{value} is not a valid role"}

  after_initialize :set_default_role, if: :new_record?

  # Scopes
  scope :admins, -> { where(role: "admin") }
  scope :operatives, -> { where(role: "operative") }
  scope :online, -> { where.not(current_room_id: nil) }
  scope :in_room, ->(room) { where(current_room: room) }

  # Role checks
  def admin?
    role == "admin"
  end

  def operative?
    role == "operative"
  end

  private

  def set_default_role
    self.role ||= "operative"
  end
end
