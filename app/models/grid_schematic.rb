# frozen_string_literal: true

# == Schema Information
#
# Table name: grid_schematics
# Database name: primary
#
#  id                        :integer          not null, primary key
#  description               :text
#  name                      :string           not null
#  output_quantity           :integer          default(1), not null
#  position                  :integer          default(0), not null
#  published                 :boolean          default(FALSE), not null
#  required_achievement_slug :string
#  required_clearance        :integer          default(0), not null
#  required_mission_slug     :string
#  required_room_type        :string
#  slug                      :string           not null
#  xp_reward                 :integer          default(0), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  output_definition_id      :integer          not null
#
# Indexes
#
#  index_grid_schematics_on_output_definition_id  (output_definition_id)
#  index_grid_schematics_on_slug                  (slug) UNIQUE
#
# Foreign Keys
#
#  output_definition_id  (output_definition_id => grid_item_definitions.id)
#
class GridSchematic < ApplicationRecord
  has_paper_trail

  ROOM_TYPE_LABELS = {
    "den" => "the Workbench in your Den"
  }.freeze

  belongs_to :output_definition, class_name: "GridItemDefinition"
  has_many :ingredients, class_name: "GridSchematicIngredient", dependent: :destroy
  has_many :input_definitions, through: :ingredients

  accepts_nested_attributes_for :ingredients,
    allow_destroy: true,
    reject_if: ->(attrs) { attrs["input_definition_id"].blank? }

  validates :slug, presence: true, uniqueness: true,
    format: {with: /\A[a-z0-9-]+\z/, message: "only lowercase letters, numbers, and hyphens"}
  validates :name, presence: true
  validates :output_quantity, numericality: {only_integer: true, greater_than_or_equal_to: 1}
  validates :xp_reward, numericality: {only_integer: true, greater_than_or_equal_to: 0}
  validates :required_clearance, numericality: {only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 99}
  validates :required_room_type, inclusion: {in: ROOM_TYPE_LABELS.keys, allow_nil: true}

  scope :published, -> { where(published: true) }
  scope :non_tutorial, -> { where(output_definition_id: GridItemDefinition.where(tutorial: false).select(:id)) }
  scope :ordered, -> { order(:position, :name) }

  def to_param
    slug
  end

  # Check if a hackr meets all visibility/access gates for this schematic.
  # Clearance is always checked. Mission + achievement gates are optional
  # (nil = no gate). Returns true if all gates pass.
  #
  # For batch checks, pass pre-loaded sets to avoid N+1 queries:
  #   completed_mission_slugs: Set of slug strings
  #   earned_achievement_slugs: Set of slug strings
  #   current_room: GridRoom or nil — checked against required_room_type
  NOT_PROVIDED = Object.new.freeze
  private_constant :NOT_PROVIDED

  def craftable_by?(hackr, completed_mission_slugs: nil, earned_achievement_slugs: nil, current_room: NOT_PROVIDED)
    return false unless hackr.stat("clearance").to_i >= required_clearance

    if required_room_type.present? && current_room != NOT_PROVIDED
      return false unless room_type_satisfied?(hackr, current_room)
    end

    if required_mission_slug.present?
      if completed_mission_slugs
        return false unless completed_mission_slugs.include?(required_mission_slug)
      else
        return false unless hackr.grid_hackr_missions
          .where(status: "completed")
          .joins(:grid_mission)
          .where(grid_missions: {slug: required_mission_slug})
          .exists?
      end
    end

    if required_achievement_slug.present?
      if earned_achievement_slugs
        return false unless earned_achievement_slugs.include?(required_achievement_slug)
      else
        return false unless hackr.grid_hackr_achievements
          .joins(:grid_achievement)
          .where(grid_achievements: {slug: required_achievement_slug})
          .exists?
      end
    end

    true
  end

  # Human-readable label for the room type requirement.
  def room_type_label
    return nil unless required_room_type.present?
    ROOM_TYPE_LABELS[required_room_type] || "a #{required_room_type.titleize}"
  end

  private

  # Check if hackr's current room satisfies the required_room_type.
  def room_type_satisfied?(hackr, current_room)
    return false unless current_room

    if required_room_type == "den"
      current_room.owned_den_of?(hackr)
    else
      current_room.room_type == required_room_type
    end
  end
end
