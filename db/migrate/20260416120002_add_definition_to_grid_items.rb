class AddDefinitionToGridItems < ActiveRecord::Migration[8.1]
  def up
    add_reference :grid_items, :grid_item_definition, null: true, foreign_key: true, index: true

    # Backfill: create definitions from existing items, link them
    if GridItem.any?
      GridItem.find_each do |item|
        slug = item.name.parameterize
        defn = GridItemDefinition.find_or_create_by!(slug: slug) do |d|
          d.name = item.name
          d.description = item.description
          d.item_type = item.item_type || "tool"
          d.rarity = item.rarity || "common"
          d.value = item.value || 0
          d.properties = item.properties || {}
        end
        item.update_column(:grid_item_definition_id, defn.id)
      end
    end

    change_column_null :grid_items, :grid_item_definition_id, false
  end

  def down
    remove_reference :grid_items, :grid_item_definition
  end
end
