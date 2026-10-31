# The /root console — every admin screen on the family in console.css
# (+ root_console.css; the music screens set the idiom 2026-10-30, the
# rest of the admin follows section by section): the destination rows a
# screen ends on, the "> " prompt's hint, the ledgers' [NN], filter rows
# and pagers, badges and the hidden DELETE forms the ghost buttons
# submit (field errors are ConsoleFormBuilder's). Admin views only (the
# admin layout). Music-only readouts stay in Admin::MusicConsoleHelper.
module Admin::ConsoleHelper
  # One destination table per section of the admin: [TAG, route (a route
  # helper name, or a lambda run in the view — nil drops the row: MAP
  # before any region exists), name, description, dev] — the tag doubles
  # as the prompt command (the terminal controller reads
  # a[data-command]). `dev: true` rows only show while
  # dev_tools_enabled?. Every screen's // DESTINATIONS // is its
  # section's rows + [ROOT]; the dashboard lists every section.
  ROOT_SECTIONS = {
    music: [
      ["ARTISTS", :admin_artists_path, "Artists", "Every act on record — bands, OSTs, voiceovers"],
      ["RELEASES", :admin_releases_path, "Releases", "Albums, EPs and singles across the catalog"],
      ["TRACKS", :admin_tracks_path, "Tracks", "Every transmission — audio, lyrics, frequencies"],
      ["RADIO", :admin_radio_stations_path, "Radio", "The hackr.fm stations and their playlists"]
    ],
    content: [
      ["LOGS", :admin_hackr_logs_path, "Logs", "Hackr logs — the resistance transmissions"],
      ["CODEX", :admin_codex_entries_path, "Codex", "The wiki — seven entry types"],
      ["SECTIONS", :admin_handbook_sections_path, "Handbook sections", "The Hackr Handbook's chapters"],
      ["ARTICLES", :admin_handbook_articles_path, "Handbook articles", "The Hackr Handbook's articles"],
      ["EMOTES", :admin_emotes_path, "Emotes", "The :slug: emotes shared by the WIRE and the uplink"],
      ["REDIRECTS", :admin_redirects_path, "Redirects", "Legacy paths and short links"]
    ],
    streams: [
      ["STREAMS", :admin_hackr_streams_path, "Streams", "Hackr streams and the schedule"],
      ["RADIO", :admin_radio_stations_path, "Radio", "The hackr.fm stations and their playlists"],
      ["PLAYLISTS", :admin_zone_playlists_path, "Zone playlists", "What each grid zone plays"],
      ["OVERLAYS", :admin_overlays_path, "Overlays", "The HUD's now-playing surface"],
      ["ALERTS", :admin_overlay_alerts_path, "Alerts", "The HUD's alert queue"],
      ["FEED", :admin_world_event_feed_index_path, "World feed", "The simulant population's event feed"]
    ],
    moderation: [
      ["WIRE", :admin_pulse_wire_index_path, "PulseWire", "Every pulse on the WIRE"],
      ["DROPS", :pulse_drops_admin_pulse_wire_index_path, "Pulse drops", "Pulses taken off the WIRE"],
      ["UPLINK", :admin_uplink_index_path, "Uplink", "Channels, order and the live stage"],
      ["PACKETS", :packets_admin_uplink_index_path, "Packets", "Every packet on the uplink"],
      ["PUNISH", :punishments_admin_uplink_index_path, "Punishments", "Squelches and blackouts in force"],
      ["MODLOG", :moderation_log_admin_uplink_index_path, "Moderation log", "Who did what to whom"],
      ["GRID", :admin_grid_path, "Grid", "Broadcast, who is online, feature grants"]
    ],
    world: [
      ["REGIONS", :admin_grid_regions_path, "Regions", "The grid's 17 regions"],
      ["ZONES", :admin_grid_zones_path, "Zones", "Every zone and its region"],
      ["ROOMS", :admin_grid_rooms_path, "Rooms", "Every room on the grid"],
      ["EXITS", :admin_grid_exits_path, "Exits", "Every exit between rooms"],
      ["MOBS", :admin_grid_mobs_path, "Mobs", "NPCs, vendors and their dialogue"],
      ["STARTS", :admin_grid_starting_rooms_path, "Starting rooms", "Where a new hackr boots"],
      ["FACTIONS", :admin_grid_factions_path, "Factions", "The seven factions and their reputation"],
      ["TRANSIT", :admin_grid_transit_types_path, "Transit types", "The local vehicle types"],
      ["ROUTES", :admin_grid_transit_routes_path, "Transit routes", "Local routes and their stops"],
      ["JOURNEYS", :admin_grid_transit_journeys_path, "Journeys", "Transit journeys in progress"],
      ["SLIPSTREAM", :admin_grid_slipstream_routes_path, "Slipstream", "Region-scale routes and their legs"],
      ["MAP", ->(view) { (region = GridRegion.first) && view.admin_grid_map_editor_region_show_path(region_id: region.id) }, "Map editor", "The zone map editor"],
      ["EXPORT", :admin_grid_world_export_path, "World export", "The world as YAML"]
    ],
    systems: [
      ["ITEMS", :admin_grid_item_definitions_path, "Item definitions", "The item catalog"],
      ["SCHEMATICS", :admin_grid_schematics_path, "Schematics", "Fabrication recipes and salvage"],
      ["SHOPS", :admin_grid_shop_listings_path, "Shops", "What the vendors sell"],
      ["SALES", :admin_grid_shop_transactions_path, "Shop transactions", "Every purchase and sale"],
      ["ACHIEVEMENTS", :admin_grid_achievements_path, "Achievements", "The achievement catalog"],
      ["MISSIONS", :admin_grid_missions_path, "Missions", "Missions, objectives and rewards"],
      ["ARCS", :admin_grid_mission_arcs_path, "Mission arcs", "Missions in sequence"],
      ["WIZARD", :new_admin_grid_mission_wizard_path, "Mission wizard", "A mission in seven steps"],
      ["BREACH", :admin_grid_breach_templates_path, "Breach templates", "The BREACH encounter templates"],
      ["ENCOUNTERS", :admin_grid_breach_encounters_path, "Breach encounters", "Templates placed in rooms"],
      ["ECONOMY", :admin_grid_economy_path, "Economy", "CRED supply, mining and sinks"],
      ["TRANSACTIONS", :admin_grid_transactions_path, "Transactions", "Every CRED movement"],
      ["REPLOG", :admin_grid_reputation_events_path, "Rep log", "Faction reputation events"],
      ["REPUTATIONS", :admin_grid_hackr_reputations_path, "Reputations", "Every hackr's standing per faction"],
      ["ASSIGNMENTS", :admin_grid_hackr_missions_path, "Hackr missions", "Missions taken by hackrs"],
      ["IMPOUND", :admin_grid_impound_records_path, "Impound", "Vehicles and gear held by GovCorp"]
    ],
    hackrs: [
      ["HACKRS", :admin_grid_hackrs_path, "Hackrs", "Every account — inspector, stats, warp, rig, items"],
      ["SANDBOX", :new_admin_grid_breach_sandbox_path, "Breach sandbox", "Run a BREACH as any hackr", true],
      ["NPC", :new_admin_grid_npc_dialogue_tester_path, "NPC tester", "Walk a mob's dialogue tree", true],
      ["PAC", :new_admin_grid_pac_escape_tester_path, "PAC tester", "Run a GovCorp escape", true]
    ],
    meta: [
      ["ERRORS", :admin_error_groups_path, "Errors", "Error groups from the telemetry DB"],
      ["FLAGS", :admin_data_audit_flags_path, "Red flags", "Data audit findings"],
      ["ANALYTICS", :admin_analytics_dashboard_path, "Analytics", "Page views, vitals and tunes"],
      ["GUIDE", :admin_test_guide_path, "Test guide", "The manual test articles"],
      ["RUNS", :admin_test_runs_path, "Test runs", "Recorded test runs"]
    ]
  }.freeze

  ROOT_ROW = ["ROOT", :admin_root_path, "Dashboard", "Back to the /root overview"].freeze

  # A section's rows as [tag, href, name, desc], dev-tool rows gated,
  # rows with no destination (a lambda's nil) dropped.
  def root_section_rows(section)
    ROOT_SECTIONS.fetch(section).filter_map do |tag_name, route, name, desc, dev|
      next if dev && !dev_tools_enabled?
      href = route.is_a?(Proc) ? route.call(self) : public_send(route)
      [tag_name, href, name, desc] if href
    end
  end

  # The // DESTINATIONS // rows of a screen in `section`: its rows +
  # [ROOT], minus the screen's own tag.
  def root_destinations(section, except: nil)
    rows = root_section_rows(section)
    rows << [ROOT_ROW[0], public_send(ROOT_ROW[1]), ROOT_ROW[2], ROOT_ROW[3]]
    rows.reject { |tag_name, *| tag_name == except }
  end

  # "type a track number (01–99) or type a tag (new releases …) · enter ·
  # ? help". section / except: the screen's destinations minus its own
  # tag; numbers: its numbered rows (a range past eight); extra: commands
  # the bar adds (new).
  def root_prompt_hint(section, except: nil, numbers: [], noun: "a number", extra: [])
    tags = extra + root_destinations(section, except: except).map { |t, *| t.downcase }
    parts = []
    if numbers.any?
      shown = (numbers.size > 8) ? "#{numbers.first}–#{numbers.last}" : numbers.join(" ")
      parts << safe_join(["type #{noun} ", tag.span("(#{shown})", class: "console-dim"), " or "])
    end
    parts << "type a tag " << tag.span("(#{tags.join(" ")})", class: "console-dim") << " · enter · ? help"
    safe_join(parts)
  end

  # The ledgers' [NN] — two digits, or as wide as the ledger (total:).
  def root_num(index, total: nil)
    format("%0#{[2, total.to_s.size].max}d", index + 1)
  end

  # A status row around *_tag inputs (filter forms with no form object):
  # the key is a <label for=> when the input's id is given.
  def root_field(label, id: nil, &block)
    key_tag = id ? tag.label(label, class: "console-key", for: id) : tag.span(label, class: "console-key")
    tag.div(class: "console-status-row rc-field") do
      key_tag + tag.span(class: "console-val", &block)
    end
  end

  # [<] PREV · n–m of t · [>] NEXT for an offset-paged ledger, keeping the
  # request's other query parameters. Nothing when everything fits.
  def root_pager(offset, per_page, total)
    return if total <= per_page
    first = offset + 1
    last = [offset + per_page, total].min
    query = request.query_parameters.except("offset")
    page = ->(at) { "#{request.path}?#{query.merge("offset" => at).to_query}" }
    parts = []
    parts << if offset > 0
      link_to("[<] PREV", page.call([offset - per_page, 0].max), class: "rc-btn")
    else
      tag.span("[<] PREV", class: "rc-btn", disabled: true)
    end
    parts << tag.span("#{first}–#{last} of #{total}", class: "rc-count")
    parts << if last < total
      link_to("[>] NEXT", page.call(offset + per_page), class: "rc-btn")
    else
      tag.span("[>] NEXT", class: "rc-btn", disabled: true)
    end
    tag.div(safe_join(parts), class: "rc-pager")
  end

  # A bar badge: tone :hot (the admin's cyan, default), :live (phosphor),
  # :warn (DEV TOOLS), :err.
  def root_badge(word, tone = :hot)
    tag.span(word, class: "console-bar-badge rc-badge--#{tone}")
  end

  # A hidden DELETE form a ghost button elsewhere on the screen submits
  # (<button form="<id>">): the record forms can't nest a button_to, and
  # the admin layout's confirm handler reads the form's data-confirm.
  def root_delete_form(id, url, confirm: nil, data: {})
    form_with(url: url, method: :delete, id: id, local: true,
      data: data.merge(confirm: confirm).compact) { "" }
  end
end
