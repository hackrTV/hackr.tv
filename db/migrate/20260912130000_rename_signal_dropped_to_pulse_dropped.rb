# frozen_string_literal: true

# Internal signal_dropped → pulse_dropped lexicon rename (player-visible text
# already says "pulse drop" / "PULSE DROPPED BY GOVCORP"). Renames the WIRE
# moderation flag columns on pulses; the default-named index
# (index_pulses_on_signal_dropped) is renamed automatically by
# rename_column_indexes to index_pulses_on_pulse_dropped.
class RenameSignalDroppedToPulseDropped < ActiveRecord::Migration[8.1]
  def change
    rename_column :pulses, :signal_dropped, :pulse_dropped
    rename_column :pulses, :signal_dropped_at, :pulse_dropped_at
  end
end
