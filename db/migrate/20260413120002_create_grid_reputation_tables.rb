class CreateGridReputationTables < ActiveRecord::Migration[8.1]
  def change
    create_table :grid_hackr_reputations do |t|
      t.references :grid_hackr, null: false, foreign_key: true, index: true
      t.string :subject_type, null: false
      t.bigint :subject_id, null: false
      t.integer :value, default: 0, null: false
      t.timestamps
    end
    add_index :grid_hackr_reputations, [:grid_hackr_id, :subject_type, :subject_id],
      unique: true, name: "index_hackr_reputations_unique"
    add_index :grid_hackr_reputations, [:subject_type, :subject_id],
      name: "index_hackr_reputations_on_subject"

    create_table :grid_reputation_events do |t|
      t.references :grid_hackr, null: false, foreign_key: true, index: true
      t.string :subject_type, null: false
      t.bigint :subject_id, null: false
      t.integer :delta, null: false
      t.integer :value_after, null: false
      t.string :reason
      t.string :source_type
      t.bigint :source_id
      t.text :note
      t.datetime :created_at, null: false
    end
    add_index :grid_reputation_events, [:grid_hackr_id, :created_at],
      order: {created_at: :desc}, name: "index_rep_events_on_hackr_and_time"
    add_index :grid_reputation_events, [:subject_type, :subject_id, :created_at],
      order: {created_at: :desc}, name: "index_rep_events_on_subject_and_time"
    add_index :grid_reputation_events, [:source_type, :source_id],
      name: "index_rep_events_on_source"
  end
end
