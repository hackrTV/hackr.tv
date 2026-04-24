class RenameFirmwareSlotCountToModuleSlotCountInGridItems < ActiveRecord::Migration[8.1]
  def up
    GridItem.where(item_type: "gear").where("properties->>'firmware_slot_count' IS NOT NULL").find_each do |item|
      val = item.properties.delete("firmware_slot_count")
      item.properties["module_slot_count"] = val
      item.save!
    end
  end

  def down
    GridItem.where(item_type: "gear").where("properties->>'module_slot_count' IS NOT NULL").find_each do |item|
      val = item.properties.delete("module_slot_count")
      item.properties["firmware_slot_count"] = val
      item.save!
    end
  end
end
