# == Schema Information
#
# Table name: grid_hackr_missions
# Database name: primary
#
#  id              :integer          not null, primary key
#  accepted_at     :datetime         not null
#  completed_at    :datetime
#  status          :string           default("active"), not null
#  turn_in_count   :integer          default(0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  grid_hackr_id   :integer          not null
#  grid_mission_id :integer          not null
#
# Indexes
#
#  index_grid_hackr_missions_on_grid_hackr_id    (grid_hackr_id)
#  index_grid_hackr_missions_on_grid_mission_id  (grid_mission_id)
#  index_hackr_missions_on_hackr_and_status      (grid_hackr_id,status)
#  index_hackr_missions_unique_active            (grid_hackr_id,grid_mission_id) UNIQUE WHERE status = 'active'
#
# Foreign Keys
#
#  grid_hackr_id    (grid_hackr_id => grid_hackrs.id) ON DELETE => cascade
#  grid_mission_id  (grid_mission_id => grid_missions.id) ON DELETE => cascade
#
class GridHackrMission < ApplicationRecord
  STATUSES = %w[active completed].freeze

  belongs_to :grid_hackr
  belongs_to :grid_mission

  has_many :grid_hackr_mission_objectives, dependent: :destroy

  validates :status, inclusion: {in: STATUSES}
  validate :one_active_instance_per_mission, on: :create

  before_validation { self.accepted_at ||= Time.current }

  scope :active, -> { where(status: "active") }
  scope :completed, -> { where(status: "completed") }
  scope :for_hackr, ->(h) { where(grid_hackr: h) }

  def active?
    status == "active"
  end

  def completed?
    status == "completed"
  end

  # Returns true once every objective row (one per mission objective) has
  # `completed_at` set. Evaluated live at `turn_in!` time — no stored
  # `ready_to_turn_in` state, which prevents drift when objectives advance
  # through async paths (login-sweep, rep changes, clearance level-ups).
  # Uses preloaded associations when available (the missions API + terminal
  # listing both preload `grid_hackr_mission_objectives` and nested
  # `grid_mission.grid_mission_objectives`). Falls back to `pluck` only
  # for unpreloaded callers so turn_in! on a fresh record still works.
  def all_objectives_completed?
    required_ids =
      if grid_mission.association(:grid_mission_objectives).loaded?
        grid_mission.grid_mission_objectives.map(&:id)
      else
        grid_mission.grid_mission_objectives.pluck(:id)
      end
    return false if required_ids.empty?

    completed_ids =
      if association(:grid_hackr_mission_objectives).loaded?
        grid_hackr_mission_objectives.select { |o| o.completed_at.present? }.map(&:grid_mission_objective_id)
      else
        grid_hackr_mission_objectives.where.not(completed_at: nil).pluck(:grid_mission_objective_id)
      end

    (required_ids - completed_ids).empty?
  end

  private

  # Completed rows accumulate for history (and count toward
  # `missions_completed_count` achievements), so there is no DB unique
  # index on (hackr, mission). Guard accept-time to prevent two active
  # instances of the same mission — repeatables re-accept by creating a
  # fresh row only AFTER the previous one is completed or destroyed.
  # Validation is `on: :create` — `id` is always nil at this point, so
  # `.where.not(id: id)` was a no-op. Dropped to match reality. The
  # DB-level partial unique index (`index_hackr_missions_unique_active`)
  # is the authoritative guard; this validator surfaces the error before
  # the INSERT for a friendlier message.
  def one_active_instance_per_mission
    return unless status == "active" && grid_hackr_id && grid_mission_id
    exists = self.class.active.where(
      grid_hackr_id: grid_hackr_id, grid_mission_id: grid_mission_id
    ).exists?
    errors.add(:base, "already has an active instance of this mission") if exists
  end
end
