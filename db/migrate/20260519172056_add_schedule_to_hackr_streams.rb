class AddScheduleToHackrStreams < ActiveRecord::Migration[8.1]
  def change
    add_column :hackr_streams, :scheduled_at, :datetime
    add_column :hackr_streams, :cancelled_at, :datetime
  end
end
