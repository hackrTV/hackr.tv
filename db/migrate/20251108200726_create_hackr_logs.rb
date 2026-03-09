class CreateHackrLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :hackr_logs do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :body, null: false
      t.boolean :published, default: false, null: false
      t.datetime :published_at
      t.string :timeline, null: false, default: "2120s"
      t.references :grid_hackr, null: false, foreign_key: true

      t.timestamps
    end
    add_index :hackr_logs, :slug, unique: true
    add_index :hackr_logs, :timeline
  end
end
