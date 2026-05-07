# frozen_string_literal: true

class CreateGridTransitTables < ActiveRecord::Migration[8.0]
  def change
    # Transit type definitions (10 vehicle/mode types + slipstream)
    create_table :grid_transit_types do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.string :category, null: false # "public", "private", "slipstream"
      t.text :description
      t.string :icon_key
      t.integer :base_fare, null: false, default: 0
      t.integer :min_clearance, null: false, default: 0
      t.boolean :published, null: false, default: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :grid_transit_types, :slug, unique: true
    add_index :grid_transit_types, :category

    # Which transit types are available in each region (0-4 per region)
    create_table :grid_region_transit_assignments do |t|
      t.references :grid_region, null: false, foreign_key: {on_delete: :cascade}
      t.references :grid_transit_type, null: false, foreign_key: {on_delete: :cascade}
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :grid_region_transit_assignments, [:grid_region_id, :grid_transit_type_id],
      unique: true, name: "index_region_transit_assignments_unique"

    # Local transit routes (public route lines within a region)
    create_table :grid_transit_routes do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.references :grid_transit_type, null: false, foreign_key: {on_delete: :restrict}
      t.references :grid_region, null: false, foreign_key: {on_delete: :restrict}
      t.boolean :loop_route, null: false, default: false
      t.boolean :active, null: false, default: true
      t.text :description
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :grid_transit_routes, :slug, unique: true
    add_index :grid_transit_routes, :active

    # Ordered stops on a local transit route
    create_table :grid_transit_stops do |t|
      t.references :grid_transit_route, null: false, foreign_key: {on_delete: :cascade}
      t.references :grid_room, null: false, foreign_key: {on_delete: :restrict}
      t.integer :position, null: false
      t.string :label
      t.boolean :is_terminus, null: false, default: false
      t.timestamps
    end
    add_index :grid_transit_stops, [:grid_transit_route_id, :position],
      unique: true, name: "index_transit_stops_route_position"

    # Inter-region slipstream route definitions
    create_table :grid_slipstream_routes do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.references :origin_region, null: false, foreign_key: {to_table: :grid_regions, on_delete: :restrict}
      t.references :destination_region, null: false, foreign_key: {to_table: :grid_regions, on_delete: :restrict}
      t.references :origin_room, null: false, foreign_key: {to_table: :grid_rooms, on_delete: :restrict}
      t.references :destination_room, null: false, foreign_key: {to_table: :grid_rooms, on_delete: :restrict}
      t.integer :min_clearance, null: false, default: 15
      t.integer :base_heat_cost, null: false, default: 10
      t.integer :detection_risk_base, null: false, default: 15
      t.boolean :active, null: false, default: true
      t.text :description
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :grid_slipstream_routes, :slug, unique: true
    add_index :grid_slipstream_routes, [:origin_region_id, :destination_region_id],
      unique: true, name: "index_slipstream_routes_origin_dest"

    # Ordered legs of a slipstream route (each with fork choices)
    create_table :grid_slipstream_legs do |t|
      t.references :grid_slipstream_route, null: false, foreign_key: {on_delete: :cascade}
      t.integer :position, null: false
      t.string :name, null: false
      t.text :description
      t.json :fork_options, null: false, default: []
      t.string :breach_template_slug
      t.timestamps
    end
    add_index :grid_slipstream_legs, [:grid_slipstream_route_id, :position],
      unique: true, name: "index_slipstream_legs_route_position"

    # Unified journey tracker (one active per hackr)
    create_table :grid_transit_journeys do |t|
      t.references :grid_hackr, null: false, foreign_key: {on_delete: :cascade}
      t.string :journey_type, null: false # "slipstream", "local_public", "local_private"
      t.string :state, null: false, default: "active"

      # Shared fields
      t.references :origin_room, foreign_key: {to_table: :grid_rooms, on_delete: :nullify}
      t.references :destination_room, foreign_key: {to_table: :grid_rooms, on_delete: :nullify}
      t.datetime :started_at, null: false

      # Slipstream fields
      t.references :grid_slipstream_route, foreign_key: {on_delete: :nullify}
      t.references :current_leg, foreign_key: {to_table: :grid_slipstream_legs, on_delete: :nullify}
      t.integer :legs_completed, null: false, default: 0
      t.boolean :pending_fork, null: false, default: false
      t.integer :heat_accumulated, null: false, default: 0
      t.boolean :breach_mid_journey, null: false, default: false

      # Local transit fields
      t.references :grid_transit_route, foreign_key: {on_delete: :nullify}
      t.references :current_stop, foreign_key: {to_table: :grid_transit_stops, on_delete: :nullify}
      t.integer :fare_paid, null: false, default: 0

      # Metadata
      t.json :meta, null: false, default: {}
      t.datetime :ended_at

      t.timestamps
    end
    add_index :grid_transit_journeys, :state
    add_index :grid_transit_journeys, :grid_hackr_id,
      unique: true, where: "state = 'active'",
      name: "index_transit_journeys_one_active_per_hackr"
  end
end
