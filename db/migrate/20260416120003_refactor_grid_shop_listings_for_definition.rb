class RefactorGridShopListingsForDefinition < ActiveRecord::Migration[8.1]
  def up
    add_reference :grid_shop_listings, :grid_item_definition, null: true, foreign_key: true, index: true

    # Backfill: match listings to definitions by name, creating if needed
    if GridShopListing.any?
      GridShopListing.find_each do |listing|
        slug = listing.read_attribute(:name)&.parameterize || "listing-#{listing.id}"
        defn = GridItemDefinition.find_or_create_by!(slug: slug) do |d|
          d.name = listing.read_attribute(:name)
          d.description = listing.read_attribute(:description)
          d.item_type = listing.read_attribute(:item_type) || "tool"
          d.rarity = listing.read_attribute(:rarity) || "common"
          d.value = listing.base_price || 0
          d.properties = listing.read_attribute(:properties) || {}
        end
        listing.update_column(:grid_item_definition_id, defn.id)
      end
    end

    change_column_null :grid_shop_listings, :grid_item_definition_id, false

    remove_column :grid_shop_listings, :name, :string
    remove_column :grid_shop_listings, :description, :text
    remove_column :grid_shop_listings, :item_type, :string
    remove_column :grid_shop_listings, :rarity, :string
    remove_column :grid_shop_listings, :properties, :json
  end

  def down
    add_column :grid_shop_listings, :name, :string
    add_column :grid_shop_listings, :description, :text
    add_column :grid_shop_listings, :item_type, :string
    add_column :grid_shop_listings, :rarity, :string
    add_column :grid_shop_listings, :properties, :json

    # Restore columns from definitions
    if GridShopListing.any?
      GridShopListing.includes(:grid_item_definition).find_each do |listing|
        defn = listing.grid_item_definition
        next unless defn
        listing.update_columns(
          name: defn.name,
          description: defn.description,
          item_type: defn.item_type,
          rarity: defn.rarity,
          properties: defn.properties
        )
      end
    end

    remove_reference :grid_shop_listings, :grid_item_definition
  end
end
