# == Schema Information
#
# Table name: grid_factions
# Database name: primary
#
#  id           :integer          not null, primary key
#  color_scheme :string
#  description  :text
#  kind         :string           default("collective"), not null
#  name         :string
#  position     :integer          default(0), not null
#  slug         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  artist_id    :integer
#  parent_id    :integer
#
# Indexes
#
#  index_grid_factions_on_kind       (kind)
#  index_grid_factions_on_parent_id  (parent_id)
#  index_grid_factions_on_slug       (slug) UNIQUE
#
# Foreign Keys
#
#  parent_id  (parent_id => grid_factions.id)
#
class GridFaction < ApplicationRecord
  KINDS = %w[collective individual system].freeze

  belongs_to :artist, optional: true
  belongs_to :parent, class_name: "GridFaction", optional: true
  has_many :children, class_name: "GridFaction", foreign_key: :parent_id, dependent: :nullify

  has_many :grid_zones
  has_many :grid_rooms, through: :grid_zones
  has_many :grid_mobs

  has_many :outgoing_rep_links,
    class_name: "GridFactionRepLink",
    foreign_key: :source_faction_id,
    dependent: :destroy,
    inverse_of: :source_faction

  has_many :incoming_rep_links,
    class_name: "GridFactionRepLink",
    foreign_key: :target_faction_id,
    dependent: :destroy,
    inverse_of: :target_faction

  has_many :rep_targets, through: :outgoing_rep_links, source: :target_faction
  has_many :rep_sources, through: :incoming_rep_links, source: :source_faction

  has_many :grid_hackr_reputations,
    as: :subject,
    dependent: :destroy

  # Polymorphic `subject` has no FK, so deletions must cascade explicitly to
  # avoid orphan audit rows whose `subject` association dangles. Source
  # pointers (mobs, admin hackrs, etc.) are intentionally left alone on those
  # models' destroy paths — historical audit is preserved even when the source
  # record is gone.
  has_many :grid_reputation_events,
    as: :subject,
    dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :kind, inclusion: {in: KINDS}
  validate :parent_not_self
  validate :parent_chain_has_no_cycle

  scope :ordered, -> { order(:position, :name) }
  scope :roots, -> { where(parent_id: nil) }

  def leaf?
    incoming_rep_links.none?
  end

  # True if other factions contribute rep to this faction via links.
  def aggregate?
    incoming_rep_links.any?
  end

  def display_name
    name.presence || slug
  end

  private

  def parent_not_self
    errors.add(:parent_id, "cannot be self") if parent_id.present? && parent_id == id
  end

  # Walk the parent chain; if we loop back to this record, reject the write.
  # Display hierarchy is authoritatively a DAG.
  def parent_chain_has_no_cycle
    return if parent_id.blank?

    current_id = parent_id
    visited = Set.new
    visited << id if persisted?
    while current_id
      if visited.include?(current_id)
        errors.add(:parent_id, "would create a hierarchy cycle")
        return
      end
      visited << current_id
      current_id = self.class.where(id: current_id).pick(:parent_id)
    end
  end
end
