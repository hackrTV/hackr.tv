class AddTutorialToGridItemDefinitions < ActiveRecord::Migration[8.1]
  def change
    add_column :grid_item_definitions, :tutorial, :boolean, default: false, null: false

    # Backfill: all training-* items are tutorial items
    reversible do |dir|
      dir.up do
        execute "UPDATE grid_item_definitions SET tutorial = TRUE WHERE slug LIKE 'training-%'"
      end
    end
  end
end
