# frozen_string_literal: true

# Internal jackout → abort lexicon rename (player-visible rename already shipped).
# Rewrites persisted breach states, breach log action types, the emergency chip
# item definition slug (item instances reference by FK id, so slug rewrite is safe),
# and the effect_type stored inside the item definition's properties JSON.
class RenameJackoutToAbort < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE grid_hackr_breaches SET state = 'aborted' WHERE state = 'jacked_out'
    SQL

    execute <<~SQL
      UPDATE grid_hackr_breach_logs SET action_type = 'abort' WHERE action_type = 'jackout'
    SQL

    execute <<~SQL
      UPDATE grid_item_definitions SET slug = 'emergency-cutoff-chip' WHERE slug = 'emergency-jackout-chip'
    SQL

    execute <<~SQL
      UPDATE grid_item_definitions
      SET properties = json_set(properties, '$.effect_type', 'emergency_cutoff')
      WHERE json_extract(properties, '$.effect_type') = 'emergency_jackout'
    SQL
  end

  def down
    execute <<~SQL
      UPDATE grid_item_definitions
      SET properties = json_set(properties, '$.effect_type', 'emergency_jackout')
      WHERE json_extract(properties, '$.effect_type') = 'emergency_cutoff'
    SQL

    execute <<~SQL
      UPDATE grid_item_definitions SET slug = 'emergency-jackout-chip' WHERE slug = 'emergency-cutoff-chip'
    SQL

    execute <<~SQL
      UPDATE grid_hackr_breach_logs SET action_type = 'jackout' WHERE action_type = 'abort'
    SQL

    execute <<~SQL
      UPDATE grid_hackr_breaches SET state = 'jacked_out' WHERE state = 'aborted'
    SQL
  end
end
