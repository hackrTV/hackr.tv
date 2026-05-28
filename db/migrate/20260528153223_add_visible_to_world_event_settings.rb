# frozen_string_literal: true

class AddVisibleToWorldEventSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :world_event_settings, :visible, :boolean, null: false, default: false
  end
end
