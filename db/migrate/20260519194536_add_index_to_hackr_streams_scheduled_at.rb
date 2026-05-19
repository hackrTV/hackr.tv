class AddIndexToHackrStreamsScheduledAt < ActiveRecord::Migration[8.1]
  def change
    add_index :hackr_streams, :scheduled_at
  end
end
