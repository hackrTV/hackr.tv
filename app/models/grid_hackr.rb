class GridHackr < ApplicationRecord
  include ProfanityFilterable

  has_secure_password

  filter_profanity :hackr_alias

  # Reserved aliases that cannot be registered (exact matches, case-insensitive)
  RESERVED_ALIASES = %w[
    admin administrator mod moderator sysop
    system root grid pulse wire codex
    govcorp fracture network
    synthia synthia_prime npc bot
    anonymous unknown guest user hackr
    help info support contact
    the_pulse the_grid the_codex
  ].freeze

  # Reserved alias patterns (regex, applied case-insensitively)
  RESERVED_ALIAS_PATTERNS = [
    /admin/,        # Contains "admin"
    /moderator/,    # Contains "moderator"
    /system/,       # Contains "system"
    /official/,     # Contains "official"
    /hackrtv/,      # Contains "hackrtv"
    /hackr_tv/,     # Contains "hackr_tv"
    /the_?pulse/,   # Contains "pulse", "the_pulse", or "thepulse"
    /govcorp/,      # Contains "govcorp"
    /fracture/,     # Contains "fracture"
    /_bot\z/,       # Ends with "_bot"
    /_npc\z/,       # Ends with "_npc"
    /_official\z/,  # Ends with "_official"
    /_admin\z/      # Ends with "_admin"
  ].freeze

  MINIMUM_ALIAS_LENGTH = 6

  # Virtual attribute to enforce length validation during UI registration
  attr_accessor :enforce_alias_length

  belongs_to :current_room, class_name: "GridRoom", optional: true
  has_many :grid_items
  has_many :grid_messages
  has_many :playlists, dependent: :destroy
  has_many :pulses, dependent: :destroy
  has_many :echoes, dependent: :destroy

  validates :hackr_alias, presence: true, uniqueness: {case_sensitive: false}
  validates :hackr_alias, length: {minimum: MINIMUM_ALIAS_LENGTH, message: "must be at least #{MINIMUM_ALIAS_LENGTH} characters"}, if: :enforce_alias_length
  validates :role, inclusion: {in: %w[operative admin], message: "%{value} is not a valid role"}
  validate :alias_not_reserved

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

  def alias_not_reserved
    return if hackr_alias.blank?

    normalized = hackr_alias.downcase.gsub(/\s+/, "_")

    # Check exact matches
    if RESERVED_ALIASES.include?(normalized)
      errors.add(:hackr_alias, "is reserved and cannot be used")
      return
    end

    # Check patterns
    if RESERVED_ALIAS_PATTERNS.any? { |pattern| normalized.match?(pattern) }
      errors.add(:hackr_alias, "is reserved and cannot be used")
    end
  end
end
