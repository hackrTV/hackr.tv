class AddAlbumToTracks < ActiveRecord::Migration[8.1]
  def change
    # Add album association and track number
    add_reference :tracks, :album, null: false, foreign_key: true
    add_column :tracks, :track_number, :integer

    # Remove old denormalized album columns
    remove_column :tracks, :album, :string
    remove_column :tracks, :album_type, :string
  end
end
