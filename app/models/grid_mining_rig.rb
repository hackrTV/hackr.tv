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
class GridMiningRig < ApplicationRecord
  belongs_to :grid_hackr
  has_many :grid_items, dependent: :nullify

  def components
    grid_items.where(item_type: "rig_component")
  end

  # --- Component queries ---

  def motherboards
    components.select { |c| c.slot == "motherboard" }
  end

  def psus
    components.select { |c| c.slot == "psu" }
  end

  def cpus
    components.select { |c| c.slot == "cpu" }
  end

  def gpus
    components.select { |c| c.slot == "gpu" }
  end

  def rams
    components.select { |c| c.slot == "ram" }
  end

  # --- Slot capacity (derived from installed motherboards) ---

  def total_cpu_slots
    motherboards.sum { |mb| (mb.properties&.dig("cpu_slots") || 1).to_i }
  end

  def total_gpu_slots
    motherboards.sum { |mb| (mb.properties&.dig("gpu_slots") || 2).to_i }
  end

  def total_ram_slots
    motherboards.sum { |mb| (mb.properties&.dig("ram_slots") || 2).to_i }
  end

  def total_psu_slots
    motherboards.count # 1 PSU per motherboard
  end

  # --- Availability checks ---

  def available_slots_for(slot_type)
    case slot_type
    when "motherboard"
      Float::INFINITY # always allowed (daisy-chain)
    when "psu"
      total_psu_slots - psus.count
    when "cpu"
      total_cpu_slots - cpus.count
    when "gpu"
      total_gpu_slots - gpus.count
    when "ram"
      total_ram_slots - rams.count
    else
      0
    end
  end

  def slot_available?(slot_type)
    available_slots_for(slot_type) > 0
  end

  # Can this motherboard be uninstalled without orphaning components?
  def can_remove_motherboard?(motherboard)
    remaining_mbs = motherboards.reject { |mb| mb.id == motherboard.id }
    remaining_cpu_slots = remaining_mbs.sum { |mb| (mb.properties&.dig("cpu_slots") || 1).to_i }
    remaining_gpu_slots = remaining_mbs.sum { |mb| (mb.properties&.dig("gpu_slots") || 2).to_i }
    remaining_ram_slots = remaining_mbs.sum { |mb| (mb.properties&.dig("ram_slots") || 2).to_i }

    cpus.count <= remaining_cpu_slots &&
      gpus.count <= remaining_gpu_slots &&
      rams.count <= remaining_ram_slots
  end

  # --- Functional check ---

  def functional?
    mb_count = motherboards.count
    mb_count > 0 &&
      psus.count >= mb_count &&
      cpus.count >= mb_count &&
      gpus.count >= mb_count &&
      rams.count >= mb_count
  end

  def functionality_errors
    mb_count = motherboards.count
    errors = []
    errors << "No motherboard installed" if mb_count.zero?
    errors << "Insufficient PSUs (need #{mb_count}, have #{psus.count})" if psus.count < mb_count
    errors << "Insufficient CPUs (need #{mb_count}, have #{cpus.count})" if cpus.count < mb_count
    errors << "Insufficient GPUs (need #{mb_count}, have #{gpus.count})" if gpus.count < mb_count
    errors << "Insufficient RAM (need #{mb_count}, have #{rams.count})" if rams.count < mb_count
    errors
  end

  # --- Rate calculation ---

  def total_multiplier
    multipliers = components.filter_map { |item| item.rate_multiplier }
    return 0.0 if multipliers.empty?
    multipliers.reduce(:*)
  end

  def effective_rate
    return 0 unless functional?
    (Grid::EconomyConfig::BASE_MINING_RATE * total_multiplier).floor
  end

  def activate!
    update!(active: true)
  end

  def deactivate!
    update!(active: false)
  end

  # Auto-deactivate if rig is no longer functional
  def check_functional!
    deactivate! if active? && !functional?
  end

  def component_summary
    comps = components.to_a.sort_by { |c| c.slot.to_s }
    return "No components installed" if comps.empty?
    comps.map { |c| "#{c.slot&.upcase}: #{c.name} (×#{c.rate_multiplier})" }.join(", ")
  end
end
