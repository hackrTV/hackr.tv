class GridHackr < ApplicationRecord
  has_secure_password

  belongs_to :current_room, class_name: "GridRoom", optional: true
  has_many :grid_items
  has_many :grid_messages
  has_many :playlists, dependent: :destroy
  has_many :pulses, dependent: :destroy
  has_many :echoes, dependent: :destroy

  validates :hackr_alias, presence: true, uniqueness: {case_sensitive: false}
  validates :role, inclusion: {in: %w[operative admin], message: "%{value} is not a valid role"}

  after_initialize :set_default_role, if: :new_record?

  # Scopes
  scope :admins, -> { where(role: "admin") }
  scope :operatives, -> { where(role: "operative") }
  scope :online, -> { recently_active.where.not(current_room_id: nil) }
  scope :in_room, ->(room) { where(current_room: room) }
  scope :recently_active, ->(since: 15.minutes.ago) { where("last_activity_at > ?", since) }

  # Role checks
  def admin?
    role == "admin"
  end

  def operative?
    role == "operative"
  end

  # Update last activity timestamp without triggering callbacks
  def touch_activity!
    update_column(:last_activity_at, Time.current)
  end

  private

  def set_default_role
    self.role ||= "operative"
  end
end
