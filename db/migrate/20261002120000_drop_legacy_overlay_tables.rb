# frozen_string_literal: true

# Retires the hackr.tv-native OBS overlay system (server-rendered /overlays
# pages + composed scenes). The external HUD app owns overlay rendering now;
# hackr.tv keeps only the data HUD reads — overlay_now_playing and
# overlay_alerts stay. Drops the scene/element/ticker/lower-third tables and
# their paper_trail history (the models are gone, so those versions can
# never be reified).
#
# `down` recreates the empty tables (schema only — dropped rows and version
# history are not restored).
class DropLegacyOverlayTables < ActiveRecord::Migration[8.1]
  DROPPED_MODELS = %w[
    OverlaySceneGroupScene OverlaySceneGroup OverlaySceneElement
    OverlayScene OverlayElement OverlayLowerThird OverlayTicker
  ].freeze

  def up
    execute <<~SQL.squish
      DELETE FROM versions
      WHERE item_type IN (#{DROPPED_MODELS.map { |m| connection.quote(m) }.join(", ")})
    SQL

    drop_table :overlay_scene_group_scenes
    drop_table :overlay_scene_groups
    drop_table :overlay_scene_elements
    drop_table :overlay_scenes
    drop_table :overlay_elements
    drop_table :overlay_lower_thirds
    drop_table :overlay_tickers
  end

  def down
    create_table :overlay_tickers do |t|
      t.boolean :active, default: true
      t.text :content, null: false
      t.string :content_type, default: "static", null: false
      t.string :direction, default: "left"
      t.string :feed_source
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :speed, default: 50
      t.timestamps
      t.index :active
      t.index :slug, unique: true
    end

    create_table :overlay_lower_thirds do |t|
      t.boolean :active, default: true
      t.string :logo_url
      t.string :name, null: false
      t.string :primary_text, null: false
      t.string :secondary_text
      t.string :slug, null: false
      t.timestamps
      t.index :active
      t.index :slug, unique: true
    end

    create_table :overlay_elements do |t|
      t.boolean :active, default: true
      t.string :element_type, null: false
      t.string :name, null: false
      t.json :settings, default: {}
      t.string :slug, null: false
      t.timestamps
      t.index :active
      t.index :element_type
      t.index :slug, unique: true
    end

    create_table :overlay_scenes do |t|
      t.boolean :active, default: true
      t.integer :height, default: 1080
      t.string :name, null: false
      t.integer :position, default: 0
      t.string :scene_type, default: "composition", null: false
      t.json :settings, default: {}
      t.string :slug, null: false
      t.integer :width, default: 1920
      t.timestamps
      t.index :active
      t.index :scene_type
      t.index :slug, unique: true
    end

    create_table :overlay_scene_elements do |t|
      t.references :overlay_scene, null: false, foreign_key: true
      t.references :overlay_element, null: false, foreign_key: true
      t.integer :height
      t.json :overrides, default: {}
      t.integer :width
      t.integer :x, default: 0
      t.integer :y, default: 0
      t.integer :z_index, default: 0
      t.timestamps
      t.index [:overlay_scene_id, :overlay_element_id], name: "idx_scene_elements_composite"
      t.index :z_index
    end

    create_table :overlay_scene_groups do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.timestamps
      t.index :slug, unique: true
    end

    create_table :overlay_scene_group_scenes do |t|
      t.references :overlay_scene_group, null: false, foreign_key: true
      t.references :overlay_scene, null: false, foreign_key: true
      t.integer :position, default: 0, null: false
      t.timestamps
      t.index [:overlay_scene_group_id, :overlay_scene_id], name: "index_scene_group_scenes_unique", unique: true
      t.index [:overlay_scene_group_id, :position], name: "index_scene_group_scenes_position"
    end
  end
end
