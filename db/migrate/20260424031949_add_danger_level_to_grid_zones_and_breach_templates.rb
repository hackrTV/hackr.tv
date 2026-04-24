# frozen_string_literal: true

class AddDangerLevelToGridZonesAndBreachTemplates < ActiveRecord::Migration[8.1]
  def change
    add_column :grid_zones, :danger_level, :integer, null: false, default: 0
    add_column :grid_breach_templates, :danger_level_min, :integer, null: false, default: 0
    add_column :grid_breach_templates, :zone_slugs, :json, null: false, default: []
  end
end
