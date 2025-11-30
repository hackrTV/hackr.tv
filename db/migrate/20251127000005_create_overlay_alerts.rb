class CreateOverlayAlerts < ActiveRecord::Migration[8.0]
  def change
    create_table :overlay_alerts do |t|
      t.string :alert_type, null: false
      t.string :title
      t.text :message
      t.json :data, default: {}
      t.boolean :displayed, default: false
      t.datetime :displayed_at
      t.datetime :expires_at

      t.timestamps
    end

    add_index :overlay_alerts, :alert_type
    add_index :overlay_alerts, :displayed
    add_index :overlay_alerts, :expires_at
  end
end
