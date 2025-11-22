class CreateEchoes < ActiveRecord::Migration[8.1]
  def change
    create_table :echoes do |t|
      t.references :pulse, null: false, foreign_key: true
      t.references :grid_hackr, null: false, foreign_key: true
      t.datetime :echoed_at, null: false

      t.timestamps
    end

    add_index :echoes, [:pulse_id, :grid_hackr_id], unique: true
    add_index :echoes, :echoed_at
  end
end
