class AddMetaToGridHackrBreaches < ActiveRecord::Migration[8.1]
  def change
    add_column :grid_hackr_breaches, :meta, :json, null: false, default: {}
  end
end
