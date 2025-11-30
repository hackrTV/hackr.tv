class CreateOverlayLowerThirds < ActiveRecord::Migration[8.0]
  def change
    create_table :overlay_lower_thirds do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :primary_text, null: false
      t.string :secondary_text
      t.string :logo_url
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :overlay_lower_thirds, :slug, unique: true
    add_index :overlay_lower_thirds, :active
  end
end
