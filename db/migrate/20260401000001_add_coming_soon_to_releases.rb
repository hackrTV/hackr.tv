class AddComingSoonToReleases < ActiveRecord::Migration[8.0]
  def change
    add_column :releases, :coming_soon, :boolean, default: false, null: false
  end
end
