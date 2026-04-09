# == Schema Information
#
# Table name: grid_caches
# Database name: primary
#
#  id            :integer          not null, primary key
#  address       :string           not null
#  archived_at   :datetime
#  is_default    :boolean          default(FALSE), not null
#  nickname      :string
#  status        :string           default("active"), not null
#  system_type   :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  grid_hackr_id :integer
#
# Indexes
#
#  index_grid_caches_on_address         (address) UNIQUE
#  index_grid_caches_on_grid_hackr_id   (grid_hackr_id)
#  index_grid_caches_on_hackr_nickname  (grid_hackr_id,nickname) UNIQUE WHERE nickname IS NOT NULL
#  index_grid_caches_on_system_type     (system_type)
#
class GridCache < ApplicationRecord
  STATUSES = %w[active abandoned].freeze
  SYSTEM_TYPES = %w[mining_pool gameplay_pool burn redemption genesis].freeze
  NICKNAME_FORMAT = /\A[a-zA-Z0-9_-]+\z/
  NICKNAME_MAX_LENGTH = 20
  RESERVED_NICKNAMES = %w[create list balance history send default abandon name].freeze

  belongs_to :grid_hackr, optional: true
  has_many :outgoing_transactions, class_name: "GridTransaction", foreign_key: :from_cache_id
  has_many :incoming_transactions, class_name: "GridTransaction", foreign_key: :to_cache_id

  validates :address, presence: true, uniqueness: true
  validates :status, inclusion: {in: STATUSES}
  validates :system_type, inclusion: {in: SYSTEM_TYPES}, allow_nil: true
  validates :nickname, length: {maximum: NICKNAME_MAX_LENGTH},
    format: {with: NICKNAME_FORMAT, message: "can only contain letters, numbers, hyphens, and underscores"},
    allow_nil: true
  validates :nickname, uniqueness: {scope: :grid_hackr_id, case_sensitive: false}, allow_nil: true
  validate :nickname_not_reserved

  scope :active, -> { where(status: "active") }
  scope :player, -> { where(system_type: nil) }
  scope :system, -> { where.not(system_type: nil) }
  scope :for_hackr, ->(hackr) { where(grid_hackr: hackr) }

  def self.mining_pool
    find_by!(system_type: "mining_pool")
  end

  def self.gameplay_pool
    find_by!(system_type: "gameplay_pool")
  end

  def self.burn
    find_by!(system_type: "burn")
  end

  def self.redemption
    find_by!(system_type: "redemption")
  end

  def self.genesis
    find_by!(system_type: "genesis")
  end

  def self.generate_address
    loop do
      address = "CACHE-#{SecureRandom.hex(2).upcase}-#{SecureRandom.hex(2).upcase}"
      break address unless exists?(address: address)
    end
  end

  def balance
    incoming_transactions.sum(:amount) - outgoing_transactions.sum(:amount)
  end

  def system?
    system_type.present?
  end

  def player?
    system_type.nil?
  end

  def active?
    status == "active"
  end

  def abandoned?
    status == "abandoned"
  end

  def abandon!
    update!(status: "abandoned", archived_at: Time.current)
  end

  def display_name
    if nickname.present?
      "#{address} (#{nickname})"
    else
      address
    end
  end

  private

  def nickname_not_reserved
    return if nickname.blank?
    if RESERVED_NICKNAMES.include?(nickname.downcase)
      errors.add(:nickname, "is reserved and cannot be used")
    end
  end
end
