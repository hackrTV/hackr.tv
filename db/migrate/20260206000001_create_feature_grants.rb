class CreateFeatureGrants < ActiveRecord::Migration[8.0]
  def change
    create_table :feature_grants do |t|
      t.references :grid_hackr, null: false, foreign_key: true
      t.string :feature, null: false

      t.timestamps
    end

    add_index :feature_grants, [:grid_hackr_id, :feature], unique: true
    add_index :feature_grants, :feature
  end
end
