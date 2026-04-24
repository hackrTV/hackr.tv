# == Schema Information
#
# Table name: grid_missions
# Database name: primary
#
#  id                  :integer          not null, primary key
#  description         :text
#  min_clearance       :integer          default(0), not null
#  min_rep_value       :integer          default(0), not null
#  name                :string           not null
#  position            :integer          default(0), not null
#  published           :boolean          default(FALSE), not null
#  repeatable          :boolean          default(FALSE), not null
#  slug                :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  giver_mob_id        :integer
#  grid_mission_arc_id :integer
#  min_rep_faction_id  :integer
#  prereq_mission_id   :integer
#
# Indexes
#
#  index_grid_missions_on_giver_mob_id         (giver_mob_id)
#  index_grid_missions_on_grid_mission_arc_id  (grid_mission_arc_id)
#  index_grid_missions_on_min_rep_faction_id   (min_rep_faction_id)
#  index_grid_missions_on_prereq_mission_id    (prereq_mission_id)
#  index_grid_missions_on_slug                 (slug) UNIQUE
#
# Foreign Keys
#
#  giver_mob_id         (giver_mob_id => grid_mobs.id) ON DELETE => nullify
#  grid_mission_arc_id  (grid_mission_arc_id => grid_mission_arcs.id) ON DELETE => nullify
#  min_rep_faction_id   (min_rep_faction_id => grid_factions.id) ON DELETE => nullify
#  prereq_mission_id    (prereq_mission_id => grid_missions.id) ON DELETE => nullify
#
class GridMission < ApplicationRecord
  has_paper_trail

  # Objective type allowlist. Extending the mission system with a new
  # action verb is a three-line change: add here, add case branch in
  # Grid::MissionProgressor#record, and wire a `progressor.record(:...)`
  # call into the command that fires the event. No schema migration.
  OBJECTIVE_TYPES = %w[
    visit_room talk_npc collect_item deliver_item
    spend_cred buy_item reach_rep reach_clearance
    use_item salvage_item salvage_yield_received
    fabricate_item
    complete_breach
    dismantle_protocols
    extract_data
  ].freeze

  # Reward type allowlist. `amount` is the scalar for XP/CRED/rep deltas;
  # `target_slug` points the row at a faction/item/achievement;
  # `quantity` scales item grants. Mission unlocks are expressed as
  # `prereq_mission_id` on the next mission — not a reward row — so
  # there's no stored no-op data and the admin UI reads prereqs directly.
  REWARD_TYPES = %w[
    xp cred faction_rep item_grant grant_achievement
  ].freeze

  belongs_to :giver_mob, class_name: "GridMob", optional: true
  belongs_to :grid_mission_arc, optional: true
  belongs_to :prereq_mission, class_name: "GridMission", optional: true
  belongs_to :min_rep_faction, class_name: "GridFaction", optional: true

  has_many :grid_mission_objectives, -> { order(:position) }, dependent: :destroy
  has_many :grid_mission_rewards, -> { order(:position) }, dependent: :destroy
  has_many :grid_hackr_missions, dependent: :destroy

  accepts_nested_attributes_for :grid_mission_objectives, allow_destroy: true,
    reject_if: ->(attrs) { attrs["objective_type"].blank? && attrs["label"].blank? }
  accepts_nested_attributes_for :grid_mission_rewards, allow_destroy: true,
    reject_if: ->(attrs) { attrs["reward_type"].blank? }

  validates :slug, presence: true, uniqueness: true
  validates :name, presence: true
  validates :giver_mob_id, presence: {message: "is required for published missions"}, if: :published?
  validate :prereq_not_self

  scope :published, -> { where(published: true) }
  scope :ordered, -> { order(:position, :name) }

  def to_param
    slug
  end

  private

  def prereq_not_self
    return unless prereq_mission_id.present? && prereq_mission_id == id
    errors.add(:prereq_mission_id, "cannot reference itself")
  end
end
