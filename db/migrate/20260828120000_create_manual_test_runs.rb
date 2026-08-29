class CreateManualTestRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :manual_test_runs do |t|
      t.string :label, null: false
      t.references :grid_hackr, null: false, foreign_key: true
      t.datetime :completed_at
      t.timestamps
    end

    create_table :manual_test_results do |t|
      t.references :manual_test_run, null: false, foreign_key: true
      t.string :article_slug, null: false
      t.string :status, null: false
      t.text :notes
      t.timestamps
    end

    add_index :manual_test_results, [:manual_test_run_id, :article_slug],
      unique: true, name: "index_manual_test_results_on_run_and_slug"
  end
end
