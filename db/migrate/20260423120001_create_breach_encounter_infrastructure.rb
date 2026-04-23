# frozen_string_literal: true

class CreateBreachEncounterInfrastructure < ActiveRecord::Migration[8.0]
  def up
    # 1. grid_breach_encounters — persistent voluntary encounters placed in rooms
    create_table :grid_breach_encounters do |t|
      t.references :grid_breach_template, null: false, foreign_key: {on_delete: :restrict}
      t.references :grid_room, null: false, foreign_key: {on_delete: :cascade}
      t.string :state, null: false, default: "available"
      t.datetime :cooldown_until
      t.integer :instance_seed

      t.timestamps
    end

    add_index :grid_breach_encounters, [:grid_room_id, :grid_breach_template_id],
      name: "index_breach_encounters_on_room_and_template"
    add_index :grid_breach_encounters, :state

    # 2. grid_hackr_breach_logs — append-only action log
    create_table :grid_hackr_breach_logs do |t|
      t.references :grid_hackr_breach, null: false, foreign_key: {on_delete: :cascade}
      t.integer :round, null: false
      t.string :action_type, null: false
      t.string :target
      t.string :program_slug
      t.json :result, null: false, default: {}
      t.datetime :created_at, null: false
    end

    add_index :grid_hackr_breach_logs, [:grid_hackr_breach_id, :round],
      name: "index_breach_logs_on_breach_and_round"

    # 3. Add encounter FK to hackr_breaches (nullable — ambient encounters have no persistent record)
    add_reference :grid_hackr_breaches, :grid_breach_encounter,
      null: true,
      foreign_key: {on_delete: :nullify}

    # 4. Backfill existing breach_template_slug rooms into encounter rows
    GridRoom.where.not(breach_template_slug: [nil, ""]).find_each do |room|
      template = GridBreachTemplate.find_by(slug: room.breach_template_slug)
      next unless template

      unless GridBreachEncounter.exists?(grid_breach_template: template, grid_room: room)
        GridBreachEncounter.create!(
          grid_breach_template: template,
          grid_room: room,
          state: "available"
        )
      end
    end

    # 5. Drop breach_template_slug from grid_rooms
    remove_column :grid_rooms, :breach_template_slug
  end

  def down
    add_column :grid_rooms, :breach_template_slug, :string

    # Restore breach_template_slug from encounter records
    GridBreachEncounter.includes(:grid_breach_template, :grid_room).find_each do |enc|
      enc.grid_room.update_columns(breach_template_slug: enc.grid_breach_template.slug)
    end

    remove_reference :grid_hackr_breaches, :grid_breach_encounter
    drop_table :grid_hackr_breach_logs
    drop_table :grid_breach_encounters
  end
end
