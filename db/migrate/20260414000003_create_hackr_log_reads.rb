class CreateHackrLogReads < ActiveRecord::Migration[8.1]
  def change
    create_table :hackr_log_reads do |t|
      t.references :grid_hackr, null: false, foreign_key: true
      t.references :hackr_log, null: false, foreign_key: true
      t.datetime :read_at, null: false
      t.timestamps
    end
    add_index :hackr_log_reads, [:grid_hackr_id, :hackr_log_id], unique: true, name: "index_hackr_log_reads_unique"
  end
end
