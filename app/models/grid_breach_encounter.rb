# frozen_string_literal: true

# == Schema Information
#
# Table name: grid_breach_encounters
# Database name: primary
#
#  id                      :integer          not null, primary key
#  cooldown_until          :datetime
#  instance_seed           :integer
#  state                   :string           default("available"), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  grid_breach_template_id :integer          not null
#  grid_room_id            :integer          not null
#
# Indexes
#
#  index_breach_encounters_on_room_and_template             (grid_room_id,grid_breach_template_id)
#  index_grid_breach_encounters_on_grid_breach_template_id  (grid_breach_template_id)
#  index_grid_breach_encounters_on_grid_room_id             (grid_room_id)
#  index_grid_breach_encounters_on_state                    (state)
#
# Foreign Keys
#
#  grid_breach_template_id  (grid_breach_template_id => grid_breach_templates.id) ON DELETE => restrict
#  grid_room_id             (grid_room_id => grid_rooms.id) ON DELETE => cascade
#
class GridBreachEncounter < ApplicationRecord
  has_paper_trail

  STATES = %w[available active cooldown depleted].freeze

  belongs_to :grid_breach_template
  belongs_to :grid_room
  has_many :grid_hackr_breaches, dependent: :nullify

  validates :state, presence: true, inclusion: {in: STATES}
  validates :grid_breach_template_id, uniqueness: {scope: :grid_room_id, message: "already placed in this room"}

  scope :available, -> { where(state: "available") }
  scope :not_depleted, -> { where.not(state: "depleted") }
  scope :for_room, ->(room) { where(grid_room: room) }

  delegate :name, :tier, :tier_label, :min_clearance, :published?, to: :grid_breach_template

  def available?
    state == "available"
  end

  def active?
    state == "active"
  end

  def cooldown?
    state == "cooldown"
  end

  def depleted?
    state == "depleted"
  end

  # Check if cooldown has expired and transition back to available
  def check_cooldown!
    return unless cooldown? && cooldown_until.present? && Time.current >= cooldown_until
    update!(state: "available", cooldown_until: nil)
  end

  # Start cooldown with randomized duration from template
  def start_cooldown!
    template = grid_breach_template
    duration = if template.cooldown_min >= template.cooldown_max
      template.cooldown_max
    else
      rand(template.cooldown_min..template.cooldown_max)
    end

    update!(
      state: "cooldown",
      cooldown_until: Time.current + duration.seconds
    )
  end

  def cooldown_remaining
    return nil unless cooldown? && cooldown_until.present?
    remaining = cooldown_until - Time.current
    (remaining > 0) ? remaining : 0
  end
end
