# frozen_string_literal: true

# == Schema Information
#
# Table name: grid_hackr_breaches
# Database name: primary
#
#  id                       :integer          not null, primary key
#  actions_remaining        :integer          default(1), not null
#  actions_this_round       :integer          default(1), not null
#  detection_level          :integer          default(0), not null
#  ended_at                 :datetime
#  inspiration              :integer          default(0), not null
#  meta                     :json             not null
#  pnr_threshold            :integer          default(75), not null
#  reward_multiplier        :decimal(5, 4)    default(1.0), not null
#  round_number             :integer          default(1), not null
#  started_at               :datetime         not null
#  state                    :string           default("active"), not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  grid_breach_encounter_id :integer
#  grid_breach_template_id  :integer          not null
#  grid_hackr_id            :integer          not null
#  origin_room_id           :integer
#
# Indexes
#
#  index_grid_hackr_breaches_on_grid_breach_encounter_id  (grid_breach_encounter_id)
#  index_grid_hackr_breaches_on_grid_breach_template_id   (grid_breach_template_id)
#  index_grid_hackr_breaches_on_grid_hackr_id             (grid_hackr_id)
#  index_grid_hackr_breaches_on_state                     (state)
#  index_hackr_breaches_one_active_per_hackr              (grid_hackr_id) UNIQUE WHERE state = 'active'
#
# Foreign Keys
#
#  grid_breach_encounter_id  (grid_breach_encounter_id => grid_breach_encounters.id) ON DELETE => nullify
#  grid_breach_template_id   (grid_breach_template_id => grid_breach_templates.id) ON DELETE => restrict
#  grid_hackr_id             (grid_hackr_id => grid_hackrs.id) ON DELETE => cascade
#  origin_room_id            (origin_room_id => grid_rooms.id) ON DELETE => nullify
#
require "rails_helper"

RSpec.describe GridHackrBreach, type: :model do
  let(:zone) { create(:grid_zone) }
  let(:room) { create(:grid_room, grid_zone: zone) }
  let(:hackr) { create(:grid_hackr, current_room: room) }
  let(:template) { create(:grid_breach_template) }

  describe "validations" do
    it "validates state inclusion" do
      breach = GridHackrBreach.new(
        grid_hackr: hackr,
        grid_breach_template: template,
        origin_room_id: room.id,
        state: "invalid",
        started_at: Time.current
      )
      expect(breach).not_to be_valid
      expect(breach.errors[:state]).to be_present
    end

    it "validates detection_level range" do
      breach = GridHackrBreach.new(
        grid_hackr: hackr,
        grid_breach_template: template,
        origin_room_id: room.id,
        state: "active",
        detection_level: 101,
        started_at: Time.current
      )
      expect(breach).not_to be_valid
    end
  end

  describe "partial unique index" do
    it "prevents two active breaches for the same hackr" do
      GridHackrBreach.create!(
        grid_hackr: hackr,
        grid_breach_template: template,
        origin_room_id: room.id,
        state: "active",
        started_at: Time.current
      )

      expect {
        GridHackrBreach.create!(
          grid_hackr: hackr,
          grid_breach_template: template,
          origin_room_id: room.id,
          state: "active",
          started_at: Time.current
        )
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "allows a new active breach after previous is completed" do
      breach = GridHackrBreach.create!(
        grid_hackr: hackr,
        grid_breach_template: template,
        origin_room_id: room.id,
        state: "active",
        started_at: Time.current
      )
      breach.update!(state: "success")

      expect {
        GridHackrBreach.create!(
          grid_hackr: hackr,
          grid_breach_template: template,
          origin_room_id: room.id,
          state: "active",
          started_at: Time.current
        )
      }.not_to raise_error
    end
  end

  describe "#pnr_crossed?" do
    it "returns false when detection is below PNR" do
      breach = build(:grid_hackr_breach, detection_level: 50, pnr_threshold: 75)
      expect(breach.pnr_crossed?).to be false
    end

    it "returns true when detection equals PNR" do
      breach = build(:grid_hackr_breach, detection_level: 75, pnr_threshold: 75)
      expect(breach.pnr_crossed?).to be true
    end
  end
end
