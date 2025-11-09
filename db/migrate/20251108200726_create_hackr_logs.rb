class CreateHackrLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :hackr_logs do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :body, null: false
      t.boolean :published, default: false, null: false
      t.datetime :published_at
      t.references :author, null: false, foreign_key: {to_table: :grid_hackrs}

      t.timestamps
    end
    add_index :hackr_logs, :slug, unique: true
  end
end
