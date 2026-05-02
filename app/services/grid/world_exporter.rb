# frozen_string_literal: true

require "rubygems/package"

module Grid
  # Exports the full world state from the database to YAML files matching
  # the seed format in data/world/. The exported YAML is the reverse of
  # data:world — same keys, same slug cross-references — so the files
  # are bidirectional: export from prod, seed into dev.
  #
  # Usage:
  #   Grid::WorldExporter.new.export_all          # writes to data/world/
  #   Grid::WorldExporter.new.export_all(dir: "/tmp/world")
  #   Grid::WorldExporter.new.to_tar_gz           # returns binary string
  class WorldExporter
    YAML_LINE_WIDTH = 120

    def initialize
      @dir = nil
    end

    # Export all world YAML files to the given directory.
    def export_all(dir: Rails.root.join("data", "world"))
      @dir = dir
      FileUtils.mkdir_p(@dir)

      export_factions
      export_regions
      export_zones
      export_rooms
      export_exits
      export_mobs
      export_item_definitions
      export_salvage_yields
      export_items
      export_achievements
      export_shop_listings
      export_missions
      export_schematics
      export_breach_templates
      export_breach_encounters

      @dir
    end

    # Generate a tar.gz archive of all exported YAML files.
    def to_tar_gz
      Dir.mktmpdir("world-export") do |tmpdir|
        export_all(dir: tmpdir)

        io = StringIO.new
        Zlib::GzipWriter.wrap(io) do |gz|
          Gem::Package::TarWriter.new(gz) do |tar|
            Dir.glob(File.join(tmpdir, "*.yml")).sort.each do |path|
              name = File.basename(path)
              content = File.read(path)
              tar.add_file_simple("world/#{name}", 0o644, content.bytesize) do |f|
                f.write(content)
              end
            end
          end
        end
        io.string
      end
    end

    private

    def write_yaml(filename, data)
      File.write(File.join(@dir, filename), data.to_yaml(line_width: YAML_LINE_WIDTH))
    end

    # ── Factions ──────────────────────────────────────────────

    def export_factions
      factions = GridFaction.order(:position, :name).map do |f|
        h = {"slug" => f.slug, "name" => f.name, "description" => f.description,
             "color_scheme" => f.color_scheme, "kind" => f.kind, "position" => f.position}
        h["artist_slug"] = f.artist&.slug if f.respond_to?(:artist) && f.artist_id.present?
        h["parent_slug"] = f.parent&.slug if f.respond_to?(:parent) && f.parent_id.present?
        h.compact
      end

      rep_links = GridFactionRepLink.includes(:source_faction, :target_faction).order(:id).map do |rl|
        {"source_slug" => rl.source_faction.slug, "target_slug" => rl.target_faction.slug,
         "weight" => rl.weight}
      end

      write_yaml("factions.yml", {"factions" => factions, "rep_links" => rep_links})
    end

    # ── Regions ───────────────────────────────────────────────

    def export_regions
      all_regions = GridRegion.order(:name).to_a
      special_ids = all_regions.flat_map { |r|
        [r.hospital_room_id, r.containment_room_id, r.facility_exit_room_id, r.facility_bribe_exit_room_id]
      }.compact.uniq
      slug_map = GridRoom.where(id: special_ids).pluck(:id, :slug).to_h

      regions = all_regions.map do |r|
        h = {"slug" => r.slug, "name" => r.name, "description" => r.description}
        h["hospital_room_slug"] = slug_map[r.hospital_room_id] if r.hospital_room_id
        h["containment_room_slug"] = slug_map[r.containment_room_id] if r.containment_room_id
        h["facility_exit_room_slug"] = slug_map[r.facility_exit_room_id] if r.facility_exit_room_id
        h["facility_bribe_exit_room_slug"] = slug_map[r.facility_bribe_exit_room_id] if r.facility_bribe_exit_room_id
        h.compact
      end
      write_yaml("regions.yml", {"regions" => regions})
    end

    # ── Zones ─────────────────────────────────────────────────

    def export_zones
      zones = GridZone.includes(:grid_region, :grid_faction).order("grid_regions.name, grid_zones.name")
        .references(:grid_region).map do |z|
        h = {"slug" => z.slug, "name" => z.name, "description" => z.description,
             "danger_level" => z.danger_level,
             "region_slug" => z.grid_region.slug}
        h["faction_slug"] = z.grid_faction.slug if z.grid_faction
        h["ambient_playlist_slug"] = z.ambient_playlist&.slug if z.ambient_playlist_id
        h.compact
      end
      write_yaml("zones.yml", {"zones" => zones})
    end

    # ── Rooms ─────────────────────────────────────────────────

    def export_rooms
      rooms = GridRoom.includes(grid_zone: :grid_region)
        .where.not(room_type: "den")
        .order("grid_regions.name, grid_zones.name, grid_rooms.name")
        .references(:grid_zone, :grid_region).map do |r|
        h = {"slug" => r.slug, "name" => r.name, "description" => r.description,
             "zone_slug" => r.grid_zone.slug, "room_type" => r.room_type,
             "min_clearance" => r.min_clearance}
        h["map_x"] = r.map_x unless r.map_x.nil?
        h["map_y"] = r.map_y unless r.map_y.nil?
        h["map_z"] = r.map_z if r.map_z != 0
        h.compact
      end
      write_yaml("rooms.yml", {"rooms" => rooms})
    end

    # ── Exits ─────────────────────────────────────────────────

    def export_exits
      exits = GridExit.includes(:from_room, :to_room)
        .order(:from_room_id, :direction).map do |e|
        next unless e.from_room&.slug && e.to_room&.slug
        h = {"from_room_slug" => e.from_room.slug, "to_room_slug" => e.to_room.slug,
             "direction" => e.direction}
        h["locked"] = true if e.locked?
        h
      end.compact
      write_yaml("exits.yml", {"exits" => exits})
    end

    # ── Mobs ──────────────────────────────────────────────────

    def export_mobs
      mobs = GridMob.includes(:grid_room, :grid_faction).order(:name).map do |m|
        next unless m.grid_room&.slug
        h = {"name" => m.name, "room_slug" => m.grid_room.slug,
             "description" => m.description, "mob_type" => m.mob_type}
        h["faction_slug"] = m.grid_faction.slug if m.grid_faction
        h["dialogue_tree"] = m.dialogue_tree if m.dialogue_tree.present?
        h["vendor_config"] = m.vendor_config if m.vendor_config.present?
        h.compact
      end.compact
      write_yaml("mobs.yml", {"mobs" => mobs})
    end

    # ── Item Definitions ──────────────────────────────────────

    def export_item_definitions
      defs = GridItemDefinition.order(:slug).map do |d|
        h = {"slug" => d.slug, "name" => d.name, "description" => d.description,
             "item_type" => d.item_type, "rarity" => d.rarity,
             "value" => d.value}
        h["max_stack"] = d.max_stack if d.max_stack
        h["properties"] = d.properties if d.properties.present?
        h.compact
      end
      write_yaml("item_definitions.yml", {"item_definitions" => defs})
    end

    # ── Salvage Yields ────────────────────────────────────────

    def export_salvage_yields
      yields = GridSalvageYield.includes(:source_definition, :output_definition)
        .order(:source_definition_id, :position).map do |y|
        {"source_slug" => y.source_definition.slug, "output_slug" => y.output_definition.slug,
         "quantity" => y.quantity, "position" => y.position}
      end
      write_yaml("salvage_yields.yml", {"salvage_yields" => yields})
    end

    # ── Items (floor items only, no player inventory) ─────────

    def export_items
      items = GridItem.where.not(room_id: nil).where(grid_hackr_id: nil, container_id: nil, equipped_slot: nil)
        .includes(:grid_item_definition, :room).order(:room_id).map do |i|
        next unless i.grid_item_definition&.slug && i.room&.slug
        h = {"definition_slug" => i.grid_item_definition.slug, "room_slug" => i.room.slug,
             "quantity" => i.quantity}
        h["value"] = i.value if i.value != i.grid_item_definition.value
        h
      end.compact
      write_yaml("items.yml", {"items" => items})
    end

    # ── Achievements ──────────────────────────────────────────

    def export_achievements
      achievements = GridAchievement.order(:category, :slug).map do |a|
        h = {"slug" => a.slug, "name" => a.name, "description" => a.description,
             "badge_icon" => a.badge_icon, "trigger_type" => a.trigger_type,
             "category" => a.category, "xp_reward" => a.xp_reward,
             "cred_reward" => a.cred_reward}
        h["trigger_data"] = a.trigger_data if a.trigger_data.present?
        h["hidden"] = true if a.hidden?
        h.compact
      end
      write_yaml("achievements.yml", {"achievements" => achievements})
    end

    # ── Shop Listings ─────────────────────────────────────────

    def export_shop_listings
      listings = GridShopListing.includes(:grid_mob, :grid_item_definition, grid_mob: :grid_room)
        .order("grid_mobs.name, grid_item_definitions.slug").references(:grid_mob).map do |l|
        next unless l.grid_mob&.grid_room&.slug
        h = {"vendor_name" => l.grid_mob.name, "room_slug" => l.grid_mob.grid_room.slug,
             "definition_slug" => l.grid_item_definition.slug,
             "base_price" => l.base_price, "sell_price" => l.sell_price,
             "max_stock" => l.max_stock, "restock_amount" => l.restock_amount,
             "restock_interval_hours" => l.restock_interval_hours}
        h["rotation_pool"] = true if l.rotation_pool?
        h["min_clearance"] = l.min_clearance if l.min_clearance > 0
        h["active"] = l.active unless l.rotation_pool? # rotation_pool items derive active state
        h.compact
      end.compact
      write_yaml("shop_listings.yml", {"shop_listings" => listings})
    end

    # ── Missions ──────────────────────────────────────────────

    def export_missions
      arcs = GridMissionArc.order(:position, :name).map do |a|
        {"slug" => a.slug, "name" => a.name, "description" => a.description,
         "position" => a.position, "published" => a.published?}
      end

      missions = GridMission.includes(:giver_mob, :grid_mission_arc, :prereq_mission,
        :min_rep_faction, :grid_mission_objectives, :grid_mission_rewards,
        giver_mob: :grid_room).order(:position, :name).map do |m|
        h = {"slug" => m.slug, "name" => m.name, "description" => m.description,
             "min_clearance" => m.min_clearance, "repeatable" => m.repeatable?,
             "position" => m.position, "published" => m.published?}
        h["arc_slug"] = m.grid_mission_arc.slug if m.grid_mission_arc
        h["giver_mob_name"] = m.giver_mob.name if m.giver_mob
        h["giver_room_slug"] = m.giver_mob.grid_room.slug if m.giver_mob&.grid_room
        h["prereq_mission_slug"] = m.prereq_mission.slug if m.prereq_mission
        h["min_rep_faction_slug"] = m.min_rep_faction.slug if m.min_rep_faction
        h["min_rep_value"] = m.min_rep_value if m.min_rep_value.to_i > 0
        h["dialogue_path"] = m.dialogue_path if m.dialogue_path.present?

        h["objectives"] = m.grid_mission_objectives.order(:position).map do |o|
          oh = {"position" => o.position, "objective_type" => o.objective_type, "label" => o.label}
          oh["target_slug"] = o.target_slug if o.target_slug.present?
          oh["target_count"] = o.target_count if o.target_count > 1
          oh.compact
        end

        h["rewards"] = m.grid_mission_rewards.order(:position).map do |r|
          rh = {"position" => r.position, "reward_type" => r.reward_type}
          rh["amount"] = r.amount if r.amount.to_i > 0
          rh["target_slug"] = r.target_slug if r.target_slug.present?
          rh["quantity"] = r.quantity if r.quantity > 1
          rh.compact
        end

        h.compact
      end

      write_yaml("missions.yml", {"arcs" => arcs, "missions" => missions})
    end

    # ── Schematics ────────────────────────────────────────────

    def export_schematics
      schematics = GridSchematic.includes(:output_definition, ingredients: :input_definition)
        .order(:position, :name).map do |s|
        h = {"slug" => s.slug, "name" => s.name, "description" => s.description,
             "output_slug" => s.output_definition.slug,
             "output_quantity" => s.output_quantity,
             "xp_reward" => s.xp_reward,
             "required_clearance" => s.required_clearance,
             "published" => s.published?, "position" => s.position}
        h["required_mission_slug"] = s.required_mission_slug if s.required_mission_slug.present?
        h["required_achievement_slug"] = s.required_achievement_slug if s.required_achievement_slug.present?
        h["required_room_type"] = s.required_room_type if s.required_room_type.present?

        h["ingredients"] = s.ingredients.order(:position).map do |i|
          {"input_slug" => i.input_definition.slug, "quantity" => i.quantity, "position" => i.position}
        end

        h.compact
      end
      write_yaml("schematics.yml", {"schematics" => schematics})
    end

    # ── Breach Templates ──────────────────────────────────────

    def export_breach_templates
      templates = GridBreachTemplate.order(:position, :name).map do |t|
        h = {"slug" => t.slug, "name" => t.name, "description" => t.description,
             "tier" => t.tier, "min_clearance" => t.min_clearance,
             "pnr_threshold" => t.pnr_threshold, "base_detection_rate" => t.base_detection_rate,
             "cooldown_min" => t.cooldown_min, "cooldown_max" => t.cooldown_max,
             "xp_reward" => t.xp_reward, "cred_reward" => t.cred_reward,
             "published" => t.published?, "position" => t.position}
        h["requires_mission_slug"] = t.requires_mission_slug if t.requires_mission_slug.present?
        h["requires_item_slug"] = t.requires_item_slug if t.requires_item_slug.present?
        h["danger_level_min"] = t.danger_level_min if t.danger_level_min.to_i > 0
        h["zone_slugs"] = t.zone_slugs if t.zone_slugs.present?
        h["protocol_composition"] = t.protocol_composition if t.protocol_composition.present?
        h["puzzle_gates"] = t.puzzle_gates if t.puzzle_gates.present?
        h["reward_table"] = t.reward_table if t.reward_table.present?
        h["no_clearance_bypass"] = true if t.no_clearance_bypass?
        h.compact
      end
      write_yaml("breach_templates.yml", {"breach_templates" => templates})
    end

    # ── Breach Encounters ─────────────────────────────────────

    def export_breach_encounters
      encounters = GridBreachEncounter.includes(:grid_breach_template, :grid_room)
        .order(:grid_room_id).map do |e|
        next unless e.grid_breach_template&.slug && e.grid_room&.slug
        h = {"template_slug" => e.grid_breach_template.slug, "room_slug" => e.grid_room.slug}
        h["state"] = e.state if e.state != "available"
        h["instance_seed"] = e.instance_seed if e.instance_seed
        h
      end.compact
      write_yaml("breach_encounters.yml", {"breach_encounters" => encounters})
    end
  end
end
