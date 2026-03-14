class CreateCodeRepositories < ActiveRecord::Migration[8.1]
  def change
    create_table :code_repositories do |t|
      t.string :name, null: false
      t.string :full_name, null: false
      t.string :slug, null: false
      t.text :description
      t.string :language
      t.string :default_branch
      t.string :homepage
      t.integer :github_id, null: false
      t.integer :stargazers_count, default: 0
      t.integer :size_kb, default: 0
      t.datetime :github_pushed_at
      t.datetime :last_synced_at
      t.string :sync_status
      t.text :sync_error
      t.boolean :visible, default: true, null: false

      t.timestamps
    end

    add_index :code_repositories, :slug, unique: true
    add_index :code_repositories, :github_id, unique: true
    add_index :code_repositories, :visible
  end
end
