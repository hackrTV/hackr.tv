# == Schema Information
#
# Table name: grid_hackrs
# Database name: primary
#
#  id               :integer          not null, primary key
#  api_token_digest :string
#  email            :string
#  hackr_alias      :string
#  last_activity_at :datetime
#  password_digest  :string
#  registration_ip  :string
#  role             :string
#  stats            :json
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  current_room_id  :integer
#
# Indexes
#
#  index_grid_hackrs_on_api_token_digest  (api_token_digest) UNIQUE
#  index_grid_hackrs_on_email             (email) UNIQUE
#  index_grid_hackrs_on_hackr_alias       (hackr_alias) UNIQUE
#  index_grid_hackrs_on_role              (role)
#
class GridHackr < ApplicationRecord
  include ProfanityFilterable
  include GridHackr::Stats

  has_paper_trail ignore: %i[password_digest api_token_digest last_activity_at stats]

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
    relay
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

  # Virtual attribute to skip reserved alias check during seeding
  attr_accessor :skip_reserved_check

  belongs_to :current_room, class_name: "GridRoom", optional: true
  has_many :grid_items
  has_many :grid_messages
  has_many :grid_caches, class_name: "GridCache", dependent: :destroy
  has_one :grid_mining_rig, dependent: :destroy
  has_many :grid_uplink_presences, dependent: :destroy
  has_many :playlists, dependent: :destroy
  has_many :pulses, dependent: :destroy
  has_many :echoes, dependent: :destroy
  has_many :chat_messages, dependent: :destroy
  has_many :user_punishments, dependent: :destroy
  has_many :moderation_logs_as_actor, class_name: "ModerationLog", foreign_key: :actor_id, dependent: :nullify
  has_many :moderation_logs_as_target, class_name: "ModerationLog", foreign_key: :target_id, dependent: :nullify
  has_many :feature_grants, dependent: :destroy
  has_many :grid_hackr_achievements, dependent: :destroy
  has_many :grid_achievements, through: :grid_hackr_achievements
  has_many :grid_shop_transactions, dependent: :nullify
  has_many :grid_hackr_reputations, dependent: :destroy
  has_many :grid_reputation_events, dependent: :destroy
  has_many :grid_hackr_track_plays, dependent: :destroy
  has_many :hackr_log_reads, dependent: :destroy
  has_many :codex_entry_reads, dependent: :destroy
  has_many :hackr_page_views, dependent: :destroy
  has_many :hackr_vod_watches, dependent: :destroy
  has_many :hackr_radio_tunes, dependent: :destroy

  validates :hackr_alias, presence: true, uniqueness: {case_sensitive: false}
  validates :hackr_alias, length: {minimum: MINIMUM_ALIAS_LENGTH, message: "must be at least #{MINIMUM_ALIAS_LENGTH} characters"}, if: :enforce_alias_length
  validates :email, uniqueness: {case_sensitive: false}, allow_nil: true
  validates :email, format: {with: URI::MailTo::EMAIL_REGEXP}, allow_nil: true
  validates :role, inclusion: {in: %w[operative operator admin], message: "%{value} is not a valid role"}
  validates :password, length: {minimum: 8, message: "must be at least 8 characters"}, if: -> { password.present? }
  validate :alias_not_reserved
  validate :password_not_weak

  after_initialize :set_default_role, if: :new_record?

  # Economy helpers
  def default_cache
    grid_caches.find_by(is_default: true)
  end

  # Provision economy: default cache + mining rig with base components
  # Idempotent — only creates what's missing.
  def provision_economy!
    unless grid_caches.any?
      grid_caches.create!(
        address: GridCache.generate_address,
        status: "active",
        is_default: true
      )
    end

    rig = grid_mining_rig || create_grid_mining_rig!(active: false)
    return if rig.components.any? # Rig already has components

    # Base motherboard: 1 CPU, 2 GPU, 2 RAM slots
    GridItem.create!(
      grid_mining_rig: rig,
      name: "Basic Motherboard",
      description: "A standard-issue board with minimal expansion. Gets the job done.",
      item_type: "component",
      rarity: "common",
      value: 10,
      properties: {slot: "motherboard", cpu_slots: 1, gpu_slots: 2, ram_slots: 2, rate_multiplier: 1.0}
    )

    GridItem.create!(
      grid_mining_rig: rig,
      name: "Basic PSU",
      description: "A reliable power supply. Keeps the lights on.",
      item_type: "component",
      rarity: "common",
      value: 5,
      properties: {slot: "psu", rate_multiplier: 1.0}
    )

    GridItem.create!(
      grid_mining_rig: rig,
      name: "Basic CPU",
      description: "A single-core processor. Slow but steady.",
      item_type: "component",
      rarity: "common",
      value: 8,
      properties: {slot: "cpu", rate_multiplier: 1.0}
    )

    GridItem.create!(
      grid_mining_rig: rig,
      name: "Basic GPU",
      description: "A standard-issue mining processor. Not fast, but it works.",
      item_type: "component",
      rarity: "common",
      value: 5,
      properties: {slot: "gpu", rate_multiplier: 1.0}
    )

    GridItem.create!(
      grid_mining_rig: rig,
      name: "Basic RAM",
      description: "A single stick of memory. Enough to boot.",
      item_type: "component",
      rarity: "common",
      value: 4,
      properties: {slot: "ram", rate_multiplier: 1.0}
    )
  end

  # Scopes
  scope :admins, -> { where(role: "admin") }
  scope :operators, -> { where(role: "operator") }
  scope :operatives, -> { where(role: "operative") }
  scope :online, -> { recently_active.where.not(current_room_id: nil) }
  scope :in_room, ->(room) { where(current_room: room) }
  scope :recently_active, ->(since: 15.minutes.ago) { where("last_activity_at > ?", since) }

  # Role checks
  def admin?
    role == "admin"
  end

  def operator?
    role == "operator"
  end

  def operative?
    role == "operative"
  end

  # Role hierarchy: admin (3) > operator (2) > operative (1)
  ROLE_LEVELS = {"operative" => 1, "operator" => 2, "admin" => 3}.freeze

  def role_level
    ROLE_LEVELS[role] || 0
  end

  def at_least_operator?
    role_level >= ROLE_LEVELS["operator"]
  end

  def at_least_admin?
    role_level >= ROLE_LEVELS["admin"]
  end

  def has_feature?(feature_name)
    admin? || feature_grants.exists?(feature: feature_name)
  end

  # Update last activity timestamp without triggering callbacks
  def touch_activity!
    update_column(:last_activity_at, Time.current)
  end

  # Generate or regenerate API token for CLI access.
  # Returns the raw token (shown once). Only the SHA-256 digest is stored.
  def generate_api_token!
    token = SecureRandom.hex(32)
    update_column(:api_token_digest, Digest::SHA256.hexdigest(token))
    token
  end

  # Authenticate a hackr by alias and raw token.
  # Returns the hackr if valid, nil otherwise.
  def self.authenticate_by_token(hackr_alias, raw_token)
    return nil if hackr_alias.blank? || raw_token.blank?

    hackr = find_by(hackr_alias: hackr_alias)
    return nil unless hackr&.api_token_digest.present?

    digest = Digest::SHA256.hexdigest(raw_token)
    return nil unless ActiveSupport::SecurityUtils.secure_compare(digest, hackr.api_token_digest)

    hackr
  end

  private

  def set_default_role
    self.role ||= "operative"
  end

  WEAK_PASSWORDS = %w[
    password asdfasdf qwerty letmein welcome monkey dragon master
    abc123 admin login trustno1 iloveyou sunshine princess football
    charlie shadow michael qwerty123 1q2w3e4r baseball
  ].freeze

  KEYBOARD_WALKS = %w[qwerty asdfgh zxcvbn qwertyuiop asdfghjkl zxcvbnm].freeze

  WEAK_PASSWORD_MESSAGE = " -- Bro, you're a hackr. Don't use a normie password!"

  def password_not_weak
    return unless password.present?

    pw = password.downcase

    weak =
      WEAK_PASSWORDS.include?(pw) ||                            # Common passwords (exact match)
      pw.start_with?("password") ||                             # Starts with "password"
      KEYBOARD_WALKS.any? { |walk| pw.start_with?(walk) } ||   # Keyboard walks
      pw.chars.uniq.length == 1 ||                              # All same character
      (pw.match?(/\A\d+\z/) && sequential_digits?(pw, :asc)) ||  # Sequential ascending digits
      (pw.match?(/\A\d+\z/) && sequential_digits?(pw, :desc))    # Sequential descending digits

    errors.add(:password, WEAK_PASSWORD_MESSAGE) if weak
  end

  def sequential_digits?(str, direction)
    digits = str.chars.map(&:to_i)
    if direction == :asc
      # Handle wrap-around: 1234567890 (9 -> 0 counts as ascending)
      digits.each_cons(2).all? { |a, b| b - a == 1 || (a == 9 && b == 0) }
    else
      digits.each_cons(2).all? { |a, b| b - a == -1 || (a == 0 && b == 9) }
    end
  end

  def alias_not_reserved
    return if hackr_alias.blank?
    return if skip_reserved_check

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
