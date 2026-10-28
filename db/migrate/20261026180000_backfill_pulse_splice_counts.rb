# pulses.splice_count was never maintained (always 0). The WIRE ledger
# makes it a counter cache on thread_root (replies anywhere in the
# thread, kept by Pulse's belongs_to). Backfill from the data; the same
# SQL repairs drift after insert_all seeds. Irreversible by design (down
# keeps the counts).
class BackfillPulseSpliceCounts < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE pulses
      SET splice_count = (SELECT COUNT(*) FROM pulses c WHERE c.thread_root_id = pulses.id)
    SQL
  end

  def down
  end
end
