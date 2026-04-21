class BackfillGridZonesRegion < ActiveRecord::Migration[8.1]
  def up
    # Ensure regions exist before backfilling
    execute <<~SQL
      INSERT INTO grid_regions (name, slug, description, created_at, updated_at)
      SELECT 'The Lakeshore', 'the-lakeshore', 'A dense urban region on the western shore of a vast freshwater inland sea — home to Sector X and the Fracture Network''s primary operations hub.', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      WHERE NOT EXISTS (SELECT 1 FROM grid_regions WHERE slug = 'the-lakeshore')
    SQL

    execute <<~SQL
      INSERT INTO grid_regions (name, slug, description, created_at, updated_at)
      SELECT 'The Riverlands', 'the-riverlands', 'River country along a great continental river — bluffs overlooking the water, dense with musical heritage.', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      WHERE NOT EXISTS (SELECT 1 FROM grid_regions WHERE slug = 'the-riverlands')
    SQL

    # Assign The Hackr Hangar to The Riverlands, everything else to The Lakeshore
    lakeshore_id = Integer(execute("SELECT id FROM grid_regions WHERE slug = 'the-lakeshore' LIMIT 1").first.fetch("id"))
    riverlands_id = Integer(execute("SELECT id FROM grid_regions WHERE slug = 'the-riverlands' LIMIT 1").first.fetch("id"))

    execute("UPDATE grid_zones SET grid_region_id = #{lakeshore_id} WHERE grid_region_id IS NULL AND slug != 'hackr-hangar'")
    execute("UPDATE grid_zones SET grid_region_id = #{riverlands_id} WHERE grid_region_id IS NULL AND slug = 'hackr-hangar'")
  end

  def down
    # No-op — region assignments are not destructively reversible
  end
end
