class AddReleaseToTracks < ActiveRecord::Migration[8.1]
  def change
    # Add release association and track number
    add_reference :tracks, :release, null: false, foreign_key: true
    add_column :tracks, :track_number, :integer

    # Remove old denormalized album columns
    remove_column :tracks, :album, :string
    remove_column :tracks, :album_type, :string
  end
end
