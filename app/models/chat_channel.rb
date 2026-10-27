# == Schema Information
#
# Table name: chat_channels
# Database name: primary
#
#  id                  :integer          not null, primary key
#  category            :string           default("COMMS"), not null
#  description         :text
#  is_active           :boolean          default(TRUE), not null
#  minimum_role        :string           default("operative"), not null
#  name                :string           not null
#  position            :integer          default(0), not null
#  requires_livestream :boolean          default(FALSE), not null
#  slow_mode_seconds   :integer          default(0), not null
#  slug                :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_chat_channels_on_is_active        (is_active)
#  index_chat_channels_on_position_and_id  (position,id)
#  index_chat_channels_on_slug             (slug) UNIQUE
#
class ChatChannel < ApplicationRecord
  has_many :chat_messages, dependent: :destroy

  validates :slug, presence: true, uniqueness: true, format: {with: /\A[a-z0-9_-]+\z/, message: "only allows lowercase letters, numbers, underscores, and hyphens"}
  validates :name, presence: true
  validates :slow_mode_seconds, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :minimum_role, inclusion: {in: GridHackr::ROLE_LEVELS.keys, message: "%{value} is not a valid role"}
  validates :category, presence: true, length: {maximum: 24},
    format: {with: /\A[A-Z0-9 _-]+\z/, message: "only allows uppercase letters, numbers, spaces, underscores, and hyphens"}
  validates :position, numericality: {only_integer: true, greater_than_or_equal_to: 0}

  # Sidebar heading (Uplink shell). Upcased so admin input lands as a
  # heading; blank falls back to the default group.
  before_validation { self.category = category.to_s.strip.upcase.presence || "COMMS" }

  scope :active, -> { where(is_active: true) }
  scope :requiring_livestream, -> { where(requires_livestream: true) }
  # Sidebar order: position, then id. Category order is first appearance
  # within this ordering (UplinkHelper#uplink_channel_groups).
  scope :ordered, -> { order(:position, :id) }

  # /root/uplink's ↑/↓: a move renumbers the whole sidebar order in steps
  # of POSITION_STEP first (the order is kept; ties — seeded channels all
  # at 0 — become distinct so a swap can take), then the channel and its
  # neighbour inside its category trade numbers. Nothing else moves:
  # the category's set of positions is unchanged, so the group keeps its
  # place among the headings.
  POSITION_STEP = 10
  MOVES = {"up" => -1, "down" => 1}.freeze

  # Where a new channel lands by default: after the current last one.
  def self.next_position
    (maximum(:position) || -POSITION_STEP) + POSITION_STEP
  end

  # Returns the neighbour swapped past, or nil at the group's edge (then
  # only the renumbering happened, which changes no order).
  def move!(direction)
    step = MOVES.fetch(direction.to_s)
    neighbour = nil
    self.class.transaction do
      ordered = self.class.ordered.to_a
      ordered.each_with_index do |channel, index|
        channel.update_column(:position, index * POSITION_STEP) if channel.position != index * POSITION_STEP
      end
      siblings = ordered.select { |channel| channel.category == category }
      index = siblings.index { |channel| channel.id == id }
      neighbour = siblings[index + step] if (index + step).between?(0, siblings.size - 1)
      if neighbour
        mine = siblings[index]
        mine.position, neighbour.position = neighbour.position, mine.position
        mine.update_column(:position, mine.position)
        neighbour.update_column(:position, neighbour.position)
      end
    end
    reload
    neighbour
  end

  # The channel the home-page dock and popout pin to (conventionally
  # slug "live", but resolved structurally so a rename can't strand them).
  def self.livestream_default
    active.requiring_livestream.order(:id).first
  end

  # Pinned, still-active packets, newest pin first (the /uplink header
  # count + pins panel). A dropped pin is parked until its restore.
  def pinned_packets
    chat_messages.active.pinned.order(pinned_at: :desc, id: :desc)
  end

  def slow_mode?
    slow_mode_seconds > 0
  end

  # Check if channel is currently available (considering livestream requirement)
  def currently_available?
    return false unless is_active?
    return HackrStream.current_live.present? if requires_livestream?
    true
  end

  # Check if a hackr can access this channel based on role requirements (for transmitting)
  def accessible_by?(hackr)
    return false unless hackr
    return false unless currently_available?

    hackr_level = hackr.role_level
    required_level = GridHackr::ROLE_LEVELS[minimum_role] || 0

    hackr_level >= required_level
  end

  # Check if channel is viewable (read-only access)
  # Anonymous users can only view livestream channels (e.g., #live)
  def viewable_by?(hackr)
    return false unless currently_available?

    # Anonymous users can only view livestream channels
    return requires_livestream? unless hackr

    # Logged-in users must meet role requirements
    accessible_by?(hackr)
  end

  # Get the broadcast stream name for ActionCable
  def stream_name
    "uplink:#{slug}"
  end
end
