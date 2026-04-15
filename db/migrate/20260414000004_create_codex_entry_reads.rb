class CreateCodexEntryReads < ActiveRecord::Migration[8.1]
  def change
    create_table :codex_entry_reads do |t|
      t.references :grid_hackr, null: false, foreign_key: true
      t.references :codex_entry, null: false, foreign_key: true
      t.datetime :read_at, null: false
      t.timestamps
    end
    add_index :codex_entry_reads, [:grid_hackr_id, :codex_entry_id], unique: true, name: "index_codex_entry_reads_unique"
  end
end
