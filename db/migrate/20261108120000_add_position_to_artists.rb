class AddPositionToArtists < ActiveRecord::Migration[8.1]
  def change
    add_column :artists, :position, :integer
    add_index :artists, :position
  end
end
