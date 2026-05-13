# == Schema Information
#
# Table name: grid_hackrs
# Database name: primary
#
#  id                      :integer          not null, primary key
#  api_token_digest        :string
#  email                   :string
#  hackr_alias             :string
#  last_activity_at        :datetime
#  login_disabled          :boolean          default(FALSE), not null
#  otp_backup_code_digests :json
#  otp_last_used_at        :integer
#  otp_required_for_login  :boolean          default(FALSE), not null
#  otp_secret              :string
#  password_digest         :string
#  registration_ip         :string
#  role                    :string
#  service_account         :boolean          default(FALSE), not null
#  stats                   :json
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  current_room_id         :integer
#  zone_entry_room_id      :integer
#
# Indexes
#
#  index_grid_hackrs_on_api_token_digest  (api_token_digest) UNIQUE
#  index_grid_hackrs_on_email             (email) UNIQUE
#  index_grid_hackrs_on_hackr_alias       (hackr_alias) UNIQUE
#  index_grid_hackrs_on_role              (role)
#
# Foreign Keys
#
#  zone_entry_room_id  (zone_entry_room_id => grid_rooms.id) ON DELETE => nullify
#
class GridHackr < ApplicationRecord
  include ProfanityFilterable
  include GridHackr::Stats
  include GridHackr::Loadout
  include GridHackr::Breach
  include GridHackr::Transit

  has_paper_trail ignore: %i[
    password_digest api_token_digest last_activity_at stats
    otp_secret otp_backup_code_digests otp_last_used_at
  ]

  has_secure_password
  encrypts :otp_secret

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
  has_many :grid_room_visits, dependent: :destroy
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
  has_many :grid_hackr_missions, dependent: :destroy
  has_many :grid_impound_records, dependent: :destroy
  has_many :grid_missions, through: :grid_hackr_missions
  has_one :den, class_name: "GridRoom", foreign_key: :owner_id
  has_many :den_invites_received, class_name: "GridDenInvite", foreign_key: :guest_id, dependent: :destroy

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

    %w[basic-motherboard basic-psu basic-cpu basic-gpu basic-ram].each do |slug|
      defn = GridItemDefinition.find_by(slug: slug)
      raise "Item definition '#{slug}' not found — run `rails data:item_definitions` first" unless defn
      GridItem.create!(defn.item_attributes.merge(grid_mining_rig: rig))
    end

    # Den chip deferred until tutorial completion (DenService crashes in Bootloader zone).
    # For hackrs bypassing tutorial, provision_den_chip! is called from TutorialService#complete!.
    provision_den_chip! unless stat("tutorial_active")
  end

  # Grant a Den Access Chip if the hackr doesn't already have one.
  # Idempotent — safe to call multiple times.
  def provision_den_chip!
    return if den.present? # Already has a den, no chip needed
    return if grid_items.joins(:grid_item_definition)
      .where(grid_item_definitions: {slug: "den-access-chip"}).exists?

    defn = GridItemDefinition.find_by(slug: "den-access-chip")
    return unless defn # Gracefully skip if definition not yet seeded

    GridItem.create!(defn.item_attributes.merge(grid_hackr: self))
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

  # Ensure hackr has a current room, spawning in the appropriate location.
  # Tutorial-active hackrs → Bootloader hub.
  # Everyone else → first starting room, hackr-tv-central, or any hub.
  def ensure_current_room!
    return if current_room.present?

    starting_room = if stat("tutorial_active")
      GridRoom.joins(:grid_zone)
        .where(grid_zones: {slug: Grid::TutorialService::TUTORIAL_HUB_ZONE_SLUG})
        .where(room_type: "hub")
        .first
    end

    starting_room ||= GridStartingRoom.ordered.first&.grid_room
    starting_room ||= GridRoom.where(room_type: "hub").first

    update!(current_room: starting_room) if starting_room
    Grid::RoomVisitRecorder.record!(hackr: self, room: starting_room) if starting_room
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

  # --- TOTP Two-Factor Authentication ---

  TOTP_ISSUER = "hackr.tv"
  TOTP_BACKUP_CODE_COUNT = 8
  TOTP_BACKUP_CODE_LENGTH = 10

  def totp
    return nil unless otp_secret.present?
    ROTP::TOTP.new(otp_secret, issuer: TOTP_ISSUER)
  end

  def verify_otp(code)
    return false unless totp
    timestamp = totp.verify(code.to_s.strip, drift_behind: 30, drift_ahead: 30, after: otp_last_used_at)
    return false unless timestamp
    update_column(:otp_last_used_at, timestamp)
    true
  end

  def otp_provisioning_uri
    totp&.provisioning_uri(hackr_alias)
  end

  def generate_backup_codes!
    raw_codes = Array.new(TOTP_BACKUP_CODE_COUNT) { SecureRandom.alphanumeric(TOTP_BACKUP_CODE_LENGTH).upcase }
    self.otp_backup_code_digests = raw_codes.map { |c| BCrypt::Password.create(c) }
    save!(validate: false)
    raw_codes
  end

  def consume_backup_code!(raw_code)
    digests = otp_backup_code_digests.to_a
    idx = digests.index { |d| BCrypt::Password.new(d) == raw_code.to_s.strip.upcase }
    return false if idx.nil?
    digests.delete_at(idx)
    update_column(:otp_backup_code_digests, digests)
    true
  end

  # NOTE: update_columns bypasses AR Encryption but is safe here since
  # we're only writing nils. Do NOT write non-nil otp_secret this way.
  def clear_totp!
    update_columns(
      otp_required_for_login: false,
      otp_secret: nil,
      otp_backup_code_digests: nil,
      otp_last_used_at: nil
    )
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
