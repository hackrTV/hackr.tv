# == Schema Information
#
# Table name: grid_mining_rigs
# Database name: primary
#
#  id            :integer          not null, primary key
#  active        :boolean          default(FALSE), not null
#  last_tick_at  :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  grid_hackr_id :integer          not null
#
# Indexes
#
#  index_grid_mining_rigs_on_grid_hackr_id  (grid_hackr_id) UNIQUE
#
require "rails_helper"

RSpec.describe GridMiningRig, type: :model do
  let(:hackr) { create(:grid_hackr) }
  let(:rig) { create(:grid_mining_rig, grid_hackr: hackr) }

  def install_component(rig, slot:, name: "Test #{slot}", rate_multiplier: 1.0, extra_props: {})
    props = {slot: slot, rate_multiplier: rate_multiplier}.merge(extra_props)
    GridItem.create!(
      grid_mining_rig: rig, name: name, item_type: "component",
      rarity: "common", value: 1, properties: props
    )
  end

  def install_base_rig(rig)
    install_component(rig, slot: "motherboard", name: "Basic MB", extra_props: {cpu_slots: 1, gpu_slots: 2, ram_slots: 2})
    install_component(rig, slot: "psu", name: "Basic PSU")
    install_component(rig, slot: "cpu", name: "Basic CPU")
    install_component(rig, slot: "gpu", name: "Basic GPU")
    install_component(rig, slot: "ram", name: "Basic RAM")
  end

  describe "#functional?" do
    it "returns false with no components" do
      expect(rig).not_to be_functional
    end

    it "returns true with a full base rig" do
      install_base_rig(rig)
      expect(rig).to be_functional
    end

    it "returns false without a PSU" do
      install_component(rig, slot: "motherboard", extra_props: {cpu_slots: 1, gpu_slots: 2, ram_slots: 2})
      install_component(rig, slot: "cpu")
      install_component(rig, slot: "gpu")
      install_component(rig, slot: "ram")
      expect(rig).not_to be_functional
    end

    it "returns false without a motherboard" do
      install_component(rig, slot: "psu")
      install_component(rig, slot: "cpu")
      install_component(rig, slot: "gpu")
      install_component(rig, slot: "ram")
      expect(rig).not_to be_functional
    end

    it "requires PSU count >= motherboard count" do
      install_component(rig, slot: "motherboard", name: "MB1", extra_props: {cpu_slots: 1, gpu_slots: 2, ram_slots: 2})
      install_component(rig, slot: "motherboard", name: "MB2", extra_props: {cpu_slots: 1, gpu_slots: 2, ram_slots: 2})
      install_component(rig, slot: "psu", name: "PSU1") # only 1 PSU for 2 boards
      install_component(rig, slot: "cpu", name: "CPU1")
      install_component(rig, slot: "cpu", name: "CPU2")
      install_component(rig, slot: "gpu", name: "GPU1")
      install_component(rig, slot: "gpu", name: "GPU2")
      install_component(rig, slot: "ram", name: "RAM1")
      install_component(rig, slot: "ram", name: "RAM2")
      expect(rig).not_to be_functional
    end

    it "requires all component counts >= motherboard count" do
      install_component(rig, slot: "motherboard", name: "MB1", extra_props: {cpu_slots: 1, gpu_slots: 2, ram_slots: 2})
      install_component(rig, slot: "motherboard", name: "MB2", extra_props: {cpu_slots: 1, gpu_slots: 2, ram_slots: 2})
      install_component(rig, slot: "psu", name: "PSU1")
      install_component(rig, slot: "psu", name: "PSU2")
      install_component(rig, slot: "cpu", name: "CPU1") # only 1 CPU for 2 boards
      install_component(rig, slot: "gpu", name: "GPU1")
      install_component(rig, slot: "gpu", name: "GPU2")
      install_component(rig, slot: "ram", name: "RAM1")
      install_component(rig, slot: "ram", name: "RAM2")
      expect(rig).not_to be_functional
      expect(rig.functionality_errors).to include(/Insufficient CPUs/)
    end
  end

  describe "#slot_available?" do
    before { install_base_rig(rig) }

    it "allows motherboard install (daisy-chain)" do
      expect(rig.slot_available?("motherboard")).to be true
    end

    it "blocks PSU when all motherboards have one" do
      expect(rig.slot_available?("psu")).to be false
    end

    it "allows GPU when slots remain" do
      expect(rig.slot_available?("gpu")).to be true # 1 installed, 2 slots
    end

    it "blocks CPU when slots full" do
      expect(rig.slot_available?("cpu")).to be false # 1 installed, 1 slot
    end

    it "opens new slots when motherboard added" do
      install_component(rig, slot: "motherboard", name: "MB2", extra_props: {cpu_slots: 2, gpu_slots: 3, ram_slots: 2})
      expect(rig.available_slots_for("cpu")).to eq(2) # 1 used of 3 total
      expect(rig.available_slots_for("psu")).to eq(1) # 1 used of 2 total
    end
  end

  describe "#can_remove_motherboard?" do
    it "allows removal when remaining boards have capacity" do
      install_base_rig(rig)
      mb2 = install_component(rig, slot: "motherboard", name: "MB2", extra_props: {cpu_slots: 1, gpu_slots: 2, ram_slots: 2})
      expect(rig.can_remove_motherboard?(mb2)).to be true
    end

    it "blocks removal when it would orphan components" do
      install_base_rig(rig)
      mb = rig.motherboards.first
      # Fill all GPU slots
      install_component(rig, slot: "gpu", name: "GPU2")
      # Now removing the only motherboard would leave 2 GPUs with 0 slots
      expect(rig.can_remove_motherboard?(mb)).to be false
    end
  end

  describe "#effective_rate" do
    it "returns 0 when non-functional" do
      expect(rig.effective_rate).to eq(0)
    end

    it "computes rate from component multipliers" do
      install_component(rig, slot: "motherboard", extra_props: {cpu_slots: 1, gpu_slots: 2, ram_slots: 2})
      install_component(rig, slot: "psu")
      install_component(rig, slot: "cpu")
      install_component(rig, slot: "gpu", rate_multiplier: 2.0)
      install_component(rig, slot: "ram")
      # All base multipliers are 1.0 except GPU at 2.0
      # Product: 1.0 * 1.0 * 1.0 * 2.0 * 1.0 = 2.0
      # BASE_MINING_RATE (1) * 2.0 = 2
      expect(rig.effective_rate).to eq(2)
    end
  end

  describe "#check_functional!" do
    it "deactivates an active rig that is non-functional" do
      install_base_rig(rig)
      rig.activate!
      expect(rig).to be_active

      # Remove the GPU to make it non-functional
      rig.gpus.first.update!(grid_mining_rig: nil, grid_hackr: hackr)
      rig.reload
      rig.check_functional!

      expect(rig).not_to be_active
    end

    it "does nothing to an already-inactive rig" do
      expect { rig.check_functional! }.not_to change { rig.active? }
    end
  end
end
