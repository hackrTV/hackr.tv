# == Schema Information
#
# Table name: pulse_pins
# Database name: primary
#
#  id            :integer          not null, primary key
#  position      :integer          default(0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  grid_hackr_id :integer          not null
#  pulse_id      :integer          not null
#
# Indexes
#
#  index_pulse_pins_on_grid_hackr_id               (grid_hackr_id)
#  index_pulse_pins_on_grid_hackr_id_and_position  (grid_hackr_id,position)
#  index_pulse_pins_on_grid_hackr_id_and_pulse_id  (grid_hackr_id,pulse_id) UNIQUE
#  index_pulse_pins_on_pulse_id                    (pulse_id)
#
# Foreign Keys
#
#  grid_hackr_id  (grid_hackr_id => grid_hackrs.id)
#  pulse_id       (pulse_id => pulses.id)
#
require "rails_helper"

RSpec.describe PulsePin, type: :model do
  let(:hackr) { create(:grid_hackr) }
  let(:pulse) { create(:pulse, grid_hackr: hackr) }

  it "pins a hackr's own pulse" do
    expect(PulsePin.new(grid_hackr: hackr, pulse: pulse)).to be_valid
  end

  it "rejects pinning another hackr's pulse" do
    pin = PulsePin.new(grid_hackr: hackr, pulse: create(:pulse))
    expect(pin).not_to be_valid
    expect(pin.errors[:pulse]).to include("must be one of your own pulses")
  end

  it "rejects pinning a signal-dropped pulse" do
    dropped = create(:pulse, :signal_dropped, grid_hackr: hackr)
    expect(PulsePin.new(grid_hackr: hackr, pulse: dropped)).not_to be_valid
  end

  it "rejects pinning the same pulse twice" do
    PulsePin.create!(grid_hackr: hackr, pulse: pulse)
    expect(PulsePin.new(grid_hackr: hackr, pulse: pulse)).not_to be_valid
  end

  it "enforces the MAX_PINS cap on create" do
    PulsePin::MAX_PINS.times do
      PulsePin.create!(grid_hackr: hackr, pulse: create(:pulse, grid_hackr: hackr))
    end
    over = PulsePin.new(grid_hackr: hackr, pulse: create(:pulse, grid_hackr: hackr))
    expect(over.save).to be false
    expect(over.errors[:base].join).to match(/at most #{PulsePin::MAX_PINS}/o)
  end

  it "exposes pinned_pulses in ascending position order" do
    first = create(:pulse, grid_hackr: hackr)
    second = create(:pulse, grid_hackr: hackr)
    PulsePin.create!(grid_hackr: hackr, pulse: first, position: 1)
    PulsePin.create!(grid_hackr: hackr, pulse: second, position: 0)
    expect(hackr.pinned_pulses.to_a).to eq([second, first])
  end

  it "is destroyed (no FK error) when its pulse is deleted" do
    PulsePin.create!(grid_hackr: hackr, pulse: pulse)
    expect { pulse.destroy! }.to change(PulsePin, :count).by(-1)
  end
end
