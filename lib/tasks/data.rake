# Unified Data Loading System
# YAML files are the single source of truth for all seeded content
#
# Import Order (respecting dependencies):
# 1. catalog           (artists, releases, tracks from per-artist YAML files)
# 4. hackrs            (no deps)
# 5. channels          (no deps)
# 6. radio_stations    (no deps)
# 7. zone_playlists    (depends on tracks)
# 8. factions          (depends on artists)
# 9. zones             (depends on factions, zone_playlists)
# 10. rooms            (depends on zones)
# 11. exits            (depends on rooms)
# 12. mobs             (depends on rooms, factions)
# 13. items            (depends on rooms)
# 14. key_playlists    (depends on hackrs, tracks, radio_stations)
# 15. codex            (no deps)
# 16. hackr_logs       (depends on hackrs)
# 17. wire             (depends on hackrs) - sets is_seed: true
# 18. vidz             (depends on artists) - HackrStream VODs
# 19. overlay_elements (no deps)
# 20. overlay_tickers  (no deps)
# 21. overlay_lower_thirds (no deps)
# 22. overlay_scenes   (no deps)
# 23. overlay_scene_elements (depends on scenes, elements)
# 24. overlay_scene_groups (depends on scenes)
# 25. redirects        (no deps)
# 26. livestream_archive (depends on audio) - derived playlist

namespace :data do
  # === Master Tasks ===
  desc "Load all data from YAML (full fresh load). Set S3_BUCKET to also load audio from S3."
  task load: :environment do
    puts "\n" + "=" * 80
    puts "LOADING ALL DATA FROM YAML FILES"
    puts "=" * 80 + "\n"

    Rake::Task["data:catalog"].invoke
    Rake::Task["data:system"].invoke
    Rake::Task["data:world"].invoke
    Rake::Task["data:playlists"].invoke
    Rake::Task["data:content"].invoke
    Rake::Task["data:vidz"].invoke
    Rake::Task["data:overlays"].invoke

    if ENV["S3_BUCKET"].present?
      puts "\n" + "-" * 80
      puts "S3_BUCKET detected - loading audio files..."
      puts "-" * 80 + "\n"
      Rake::Task["data:audio"].invoke
    end

    Rake::Task["data:livestream_archive"].invoke
    Rake::Task["data:economy"].invoke

    puts "\n" + "=" * 80
    puts "DATA LOAD COMPLETE"
    puts "=" * 80 + "\n"
  end

  desc "Reset seed content only (preserves user data)"
  task reset: :environment do
    puts "\n=== Resetting seed content ==="
    Rake::Task["data:reset_content"].invoke
    Rake::Task["data:content"].invoke
    puts "=== Reset complete ==="
  end

  # === Layer Tasks ===
  desc "Load catalog (artists, releases, tracks) from per-artist YAML files"
  task catalog: :environment do
    puts "\n--- Loading Catalog ---"
    catalog_dir = Rails.root.join("data", "catalog")

    unless Dir.exist?(catalog_dir)
      puts "  ✗ Catalog directory not found: #{catalog_dir}"
      next
    end

    artist_files = Dir.glob(catalog_dir.join("*.yml")).sort
    if artist_files.empty?
      puts "  ✗ No artist files found in #{catalog_dir}"
      next
    end

    artists_created = artists_updated = 0
    releases_created = releases_updated = 0
    tracks_created = tracks_updated = 0

    artist_files.each do |file|
      data = YAML.load_file(file)
      artist_slug = File.basename(file, ".yml")
      artist_data = data["artist"]

      if artist_data["skip"]
        puts "  ⊘ Skipped artist: #{artist_data["name"] || artist_slug}"
        next
      end

      # Upsert artist
      artist = Artist.find_or_initialize_by(slug: artist_slug)
      was_new = artist.new_record?

      artist.assign_attributes(
        name: artist_data["name"],
        genre: artist_data["genre"],
        artist_type: artist_data["artist_type"] || "band"
      )

      if artist.changed?
        artist.save!
        was_new ? (artists_created += 1) : (artists_updated += 1)
        puts "  #{was_new ? "✓ Created" : "↻ Updated"} artist: #{artist.name}"
      end

      # Upsert releases and tracks
      (data["releases"] || []).each do |release_data|
        next unless release_data["title"].present? && release_data["slug"].present?

        if release_data["skip"]
          puts "  ⊘ Skipped release: #{release_data["title"]} (#{artist.name})"
          next
        end

        release = Release.find_or_initialize_by(artist: artist, slug: release_data["slug"])
        was_new = release.new_record?

        release_date = DataLoaderHelpers.parse_date(release_data["release_date"])

        release.assign_attributes(
          name: release_data["title"],
          release_type: release_data["release_type"],
          release_date: release_date,
          description: release_data["description"],
          catalog_number: release_data["catalog_number"],
          media_format: release_data["media_format"],
          classification: release_data["classification"],
          label: release_data["label"],
          credits: release_data["credits"],
          notes: release_data["notes"],
          streaming_links: DataLoaderHelpers.normalize_json(release_data["streaming_links"]),
          coming_soon: release_data.fetch("coming_soon", false)
        )

        if release.changed?
          release.save!
          was_new ? (releases_created += 1) : (releases_updated += 1)
          puts "  #{was_new ? "✓ Created" : "↻ Updated"} release: #{release.name} (#{artist.name})"
        end

        # Attach cover image if specified
        DataLoaderHelpers.attach_cover_image(release, release_data["cover_image"], artist_slug) if release_data["cover_image"].present?

        # Upsert tracks
        (release_data["tracks"] || []).each do |track_data|
          if track_data["skip"]
            puts "    ⊘ Skipped track: #{track_data["title"]}"
            next
          end

          track = artist.tracks.find_or_initialize_by(slug: track_data["slug"])
          was_new = track.new_record?

          track.assign_attributes(
            title: track_data["title"],
            release: release,
            track_number: track_data["track_number"],
            duration: track_data["duration"],
            cover_image: track_data["cover_image"],
            featured: track_data["featured"] || false,
            show_in_pulse_vault: track_data.fetch("show_in_pulse_vault", true),
            streaming_links: DataLoaderHelpers.normalize_json(track_data["streaming_links"]),
            videos: DataLoaderHelpers.normalize_json(track_data["videos"]),
            lyrics: track_data["lyrics"]
          )

          if track.changed?
            track.save!
            was_new ? (tracks_created += 1) : (tracks_updated += 1)
            puts "    #{was_new ? "✓ Created" : "↻ Updated"} track: #{track.title}"
          end
        end
      end
    end

    puts "Artists: #{artists_created} created, #{artists_updated} updated, #{Artist.count} total"
    puts "Releases: #{releases_created} created, #{releases_updated} updated, #{Release.count} total"
    puts "Tracks: #{tracks_created} created, #{tracks_updated} updated, #{Track.count} total"
  end

  desc "Load system data (hackrs, channels, radio stations, etc.)"
  task system: [:hackrs, :channels, :radio_stations, :zone_playlists, :redirects]

  desc "Load world data (factions, zones, rooms, etc.)"
  task world: [:factions, :zones, :rooms, :exits, :mobs, :items, :achievements, :shop_listings]

  desc "Load playlists (key playlists with radio station links)"
  task playlists: [:catalog, :hackrs, :radio_stations, :key_playlists]

  desc "Load content (codex, hackr_logs, wire)"
  task content: [:codex, :hackr_logs, :wire]

  desc "Load overlays"
  task overlays: [
    :overlay_elements, :overlay_tickers, :overlay_lower_thirds,
    :overlay_scenes, :overlay_scene_elements, :overlay_scene_groups
  ]

  # === Reset Tasks ===
  desc "Clear seed content only (preserves user data)"
  task reset_content: :environment do
    puts "Clearing seed content..."
    Pulse.where(is_seed: true).destroy_all if Pulse.column_names.include?("is_seed")
    Echo.where(is_seed: true).destroy_all if Echo.column_names.include?("is_seed")
    HackrLog.destroy_all           # All hackr_logs are seed
    CodexEntry.destroy_all         # All codex entries are seed
    puts "Seed content cleared."
  end

  desc "Clear ALL data (nuclear option - requires confirmation)"
  task clear: :environment do
    puts "\n⚠️  WARNING: This will delete ALL data including user-generated content!"
    puts "Type 'DELETE ALL DATA' to confirm:"
    confirmation = $stdin.gets.chomp
    unless confirmation == "DELETE ALL DATA"
      puts "Aborted."
      next
    end

    puts "\nClearing all data..."
    # Delete in reverse dependency order
    Echo.destroy_all
    Pulse.destroy_all
    HackrLog.destroy_all
    CodexEntry.destroy_all
    OverlaySceneGroupScene.destroy_all if defined?(OverlaySceneGroupScene)
    OverlaySceneGroup.destroy_all if defined?(OverlaySceneGroup)
    OverlaySceneElement.destroy_all
    OverlayScene.destroy_all
    OverlayLowerThird.destroy_all
    OverlayTicker.destroy_all
    OverlayElement.destroy_all
    PlaylistTrack.destroy_all
    Playlist.destroy_all
    GridItem.destroy_all
    GridMob.destroy_all
    GridExit.destroy_all
    GridMessage.destroy_all
    GridHackr.destroy_all
    GridRoom.destroy_all
    GridZone.destroy_all
    GridFaction.destroy_all
    ZonePlaylistTrack.destroy_all
    ZonePlaylist.destroy_all
    Redirect.destroy_all
    ChatMessage.destroy_all if defined?(ChatMessage)
    ChatChannel.destroy_all if defined?(ChatChannel)
    RadioStationPlaylist.destroy_all if defined?(RadioStationPlaylist)
    RadioStation.destroy_all
    Track.destroy_all
    Release.destroy_all
    Artist.destroy_all
    puts "All data cleared."
  end

  # === Individual Loaders ===

  desc "Load hackrs from YAML"
  task hackrs: :environment do
    puts "\n--- Loading Hackrs ---"
    yaml_file = Rails.root.join("data", "system", "hackrs.yml")

    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      next
    end

    data = YAML.load_file(yaml_file)
    hackrs_data = data["hackrs"]
    created = updated = 0

    hackrs_data.each do |attrs|
      hackr = GridHackr.find_or_initialize_by(hackr_alias: attrs["hackr_alias"])
      was_new = hackr.new_record?

      # Get password from env or use default
      password = if Rails.env.production?
        ENV.fetch(attrs["env_password_key"]) { raise "#{attrs["env_password_key"]} required in production" }
      else
        ENV.fetch(attrs["env_password_key"], attrs["default_password"])
      end

      hackr.assign_attributes(
        email: attrs["email"],
        role: attrs["role"],
        skip_reserved_check: true
      )

      # Only set password on new records or if explicitly changed
      if was_new
        hackr.password = password
      end

      if hackr.changed? || was_new
        hackr.save!
        was_new ? (created += 1) : (updated += 1)
        puts "  #{was_new ? "✓ Created" : "↻ Updated"}: #{hackr.hackr_alias} (#{hackr.role})"
      end
    end

    puts "Hackrs: #{created} created, #{updated} updated, #{GridHackr.count} total"
  end

  desc "Load channels from YAML"
  task channels: :environment do
    puts "\n--- Loading Channels ---"
    yaml_file = Rails.root.join("data", "system", "channels.yml")

    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      next
    end

    data = YAML.load_file(yaml_file)
    channels_data = data["channels"]
    created = updated = 0

    channels_data.each do |attrs|
      channel = ChatChannel.find_or_initialize_by(slug: attrs["slug"])
      was_new = channel.new_record?

      channel.assign_attributes(
        name: attrs["name"],
        description: attrs["description"],
        is_active: attrs["is_active"],
        requires_livestream: attrs["requires_livestream"],
        slow_mode_seconds: attrs["slow_mode_seconds"],
        minimum_role: attrs["minimum_role"]
      )

      if channel.changed?
        channel.save!
        was_new ? (created += 1) : (updated += 1)
        puts "  #{was_new ? "✓ Created" : "↻ Updated"}: #{channel.name}"
      end
    end

    puts "Channels: #{created} created, #{updated} updated, #{ChatChannel.count} total"
  end

  desc "Load radio stations from YAML"
  task radio_stations: :environment do
    puts "\n--- Loading Radio Stations ---"
    yaml_file = Rails.root.join("data", "system", "radio_stations.yml")
    yaml_file = Rails.root.join("data", "radio_stations.yml") unless File.exist?(yaml_file)

    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      next
    end

    data = YAML.load_file(yaml_file)
    stations_data = data["stations"]
    created = updated = 0

    stations_data.each do |attrs|
      station = RadioStation.find_or_initialize_by(slug: attrs["slug"])
      was_new = station.new_record?

      station.assign_attributes(
        name: attrs["name"],
        description: attrs["description"],
        genre: attrs["genre"],
        color: attrs["color"],
        stream_url: attrs["stream_url"],
        position: attrs["position"] || 0,
        hidden: attrs.fetch("hidden", false)
      )

      if station.changed?
        station.save!
        was_new ? (created += 1) : (updated += 1)
        puts "  #{was_new ? "✓ Created" : "↻ Updated"}: #{station.name}"
      end
    end

    puts "Radio Stations: #{created} created, #{updated} updated, #{RadioStation.count} total"
  end

  desc "Load zone playlists from YAML"
  task zone_playlists: :environment do
    puts "\n--- Loading Zone Playlists ---"
    yaml_file = Rails.root.join("data", "system", "zone_playlists.yml")

    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      next
    end

    data = YAML.load_file(yaml_file)
    playlists_data = data["zone_playlists"]
    created = updated = 0

    playlists_data.each do |attrs|
      playlist = ZonePlaylist.find_or_initialize_by(slug: attrs["slug"])
      was_new = playlist.new_record?

      playlist.assign_attributes(
        name: attrs["name"],
        description: attrs["description"],
        crossfade_duration_ms: attrs["crossfade_duration_ms"],
        default_volume: attrs["default_volume"]
      )

      if playlist.changed? || was_new
        playlist.save!
        was_new ? (created += 1) : (updated += 1)
        puts "  #{was_new ? "✓ Created" : "↻ Updated"}: #{playlist.name}"
      end

      # Sync tracks from artist
      if attrs["artist_tracks"].present?
        artist = Artist.find_by(slug: attrs["artist_tracks"])
        if artist
          desired_track_ids = artist.tracks.pluck(:id).to_set

          # Remove stale tracks
          playlist.zone_playlist_tracks.each do |zpt|
            unless desired_track_ids.include?(zpt.track_id)
              zpt.destroy!
            end
          end

          # Add/update track positions
          artist.tracks.each_with_index do |track, index|
            zpt = ZonePlaylistTrack.find_or_initialize_by(
              zone_playlist: playlist,
              track: track
            )
            zpt.position = index + 1
            zpt.save! if zpt.new_record? || zpt.changed?
          end
          puts "    → Synced #{artist.tracks.count} tracks from #{artist.name}"
        end
      end
    end

    puts "Zone Playlists: #{created} created, #{updated} updated, #{ZonePlaylist.count} total"
  end

  desc "Load factions from YAML"
  task factions: :environment do
    puts "\n--- Loading Factions ---"
    yaml_file = Rails.root.join("data", "world", "factions.yml")

    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      next
    end

    data = YAML.load_file(yaml_file)
    factions_data = data["factions"]
    created = updated = 0

    factions_data.each do |attrs|
      faction = GridFaction.find_or_initialize_by(slug: attrs["slug"])
      was_new = faction.new_record?

      artist = attrs["artist_slug"].present? ? Artist.find_by(slug: attrs["artist_slug"]) : nil

      faction.assign_attributes(
        name: attrs["name"],
        description: attrs["description"],
        color_scheme: attrs["color_scheme"],
        artist: artist
      )

      if faction.changed?
        faction.save!
        was_new ? (created += 1) : (updated += 1)
        puts "  #{was_new ? "✓ Created" : "↻ Updated"}: #{faction.name}"
      end
    end

    puts "Factions: #{created} created, #{updated} updated, #{GridFaction.count} total"
  end

  desc "Load zones from YAML"
  task zones: :environment do
    puts "\n--- Loading Zones ---"
    yaml_file = Rails.root.join("data", "world", "zones.yml")

    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      next
    end

    data = YAML.load_file(yaml_file)
    zones_data = data["zones"]
    created = updated = 0

    zones_data.each do |attrs|
      zone = GridZone.find_or_initialize_by(slug: attrs["slug"])
      was_new = zone.new_record?

      faction = attrs["faction_slug"].present? ? GridFaction.find_by(slug: attrs["faction_slug"]) : nil
      playlist = attrs["ambient_playlist_slug"].present? ? ZonePlaylist.find_by(slug: attrs["ambient_playlist_slug"]) : nil

      zone.assign_attributes(
        name: attrs["name"],
        description: attrs["description"],
        zone_type: attrs["zone_type"],
        color_scheme: attrs["color_scheme"],
        grid_faction: faction,
        ambient_playlist: playlist
      )

      if zone.changed?
        zone.save!
        was_new ? (created += 1) : (updated += 1)
        puts "  #{was_new ? "✓ Created" : "↻ Updated"}: #{zone.name}"
      end
    end

    puts "Zones: #{created} created, #{updated} updated, #{GridZone.count} total"
  end

  desc "Load rooms from YAML"
  task rooms: :environment do
    puts "\n--- Loading Rooms ---"
    yaml_file = Rails.root.join("data", "world", "rooms.yml")

    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      next
    end

    data = YAML.load_file(yaml_file)
    rooms_data = data["rooms"]
    created = updated = 0

    rooms_data.each do |attrs|
      room = GridRoom.find_or_initialize_by(slug: attrs["slug"])
      was_new = room.new_record?

      zone = GridZone.find_by(slug: attrs["zone_slug"])
      unless zone
        puts "  ✗ Zone not found: #{attrs["zone_slug"]}"
        next
      end

      room.assign_attributes(
        name: attrs["name"],
        description: attrs["description"],
        grid_zone: zone,
        room_type: attrs["room_type"],
        min_clearance: attrs["min_clearance"] || 0
      )

      if room.changed?
        room.save!
        was_new ? (created += 1) : (updated += 1)
        puts "  #{was_new ? "✓ Created" : "↻ Updated"}: #{room.name}"
      end
    end

    puts "Rooms: #{created} created, #{updated} updated, #{GridRoom.count} total"
  end

  desc "Load exits from YAML"
  task exits: :environment do
    puts "\n--- Loading Exits ---"
    yaml_file = Rails.root.join("data", "world", "exits.yml")

    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      next
    end

    data = YAML.load_file(yaml_file)
    exits_data = data["exits"]
    created = updated = 0

    exits_data.each do |attrs|
      from_room = GridRoom.find_by(slug: attrs["from_room_slug"])
      to_room = GridRoom.find_by(slug: attrs["to_room_slug"])

      unless from_room && to_room
        puts "  ✗ Room not found: #{attrs["from_room_slug"]} or #{attrs["to_room_slug"]}"
        next
      end

      exit_record = GridExit.find_or_initialize_by(
        from_room: from_room,
        to_room: to_room,
        direction: attrs["direction"]
      )
      was_new = exit_record.new_record?

      exit_record.locked = attrs["locked"] || false

      if exit_record.changed?
        exit_record.save!
        was_new ? (created += 1) : (updated += 1)
        puts "  #{was_new ? "✓ Created" : "↻ Updated"}: #{from_room.name} -> #{attrs["direction"]} -> #{to_room.name}"
      end
    end

    puts "Exits: #{created} created, #{updated} updated, #{GridExit.count} total"
  end

  desc "Load mobs from YAML"
  task mobs: :environment do
    puts "\n--- Loading Mobs ---"
    yaml_file = Rails.root.join("data", "world", "mobs.yml")

    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      next
    end

    data = YAML.load_file(yaml_file)
    mobs_data = data["mobs"]
    created = updated = 0

    mobs_data.each do |attrs|
      room = GridRoom.find_by(slug: attrs["room_slug"])
      faction = attrs["faction_slug"].present? ? GridFaction.find_by(slug: attrs["faction_slug"]) : nil

      unless room
        puts "  ✗ Room not found: #{attrs["room_slug"]}"
        next
      end

      mob = GridMob.find_or_initialize_by(name: attrs["name"], grid_room: room)
      was_new = mob.new_record?

      mob.assign_attributes(
        description: attrs["description"],
        mob_type: attrs["mob_type"],
        grid_faction: faction,
        dialogue_tree: attrs["dialogue_tree"],
        vendor_config: attrs["vendor_config"]
      )

      if mob.changed?
        mob.save!
        was_new ? (created += 1) : (updated += 1)
        puts "  #{was_new ? "✓ Created" : "↻ Updated"}: #{mob.name}"
      end
    end

    puts "Mobs: #{created} created, #{updated} updated, #{GridMob.count} total"
  end

  desc "Load items from YAML"
  task items: :environment do
    puts "\n--- Loading Items ---"
    yaml_file = Rails.root.join("data", "world", "items.yml")

    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      next
    end

    data = YAML.load_file(yaml_file)
    items_data = data["items"]
    created = updated = 0

    items_data.each do |attrs|
      room = GridRoom.find_by(slug: attrs["room_slug"])
      unless room
        puts "  ✗ Room not found: #{attrs["room_slug"]}"
        next
      end

      item = GridItem.find_or_initialize_by(name: attrs["name"], room: room)
      was_new = item.new_record?

      item.assign_attributes(
        description: attrs["description"],
        item_type: attrs["item_type"],
        rarity: attrs["rarity"],
        value: attrs["value"] || 0,
        quantity: attrs["quantity"] || 1,
        properties: attrs["properties"]
      )

      if item.changed?
        item.save!
        was_new ? (created += 1) : (updated += 1)
        puts "  #{was_new ? "✓ Created" : "↻ Updated"}: #{item.name}"
      end
    end

    puts "Items: #{created} created, #{updated} updated, #{GridItem.count} total"
  end

  desc "Load achievements from YAML"
  task achievements: :environment do
    puts "\n--- Loading Achievements ---"
    yaml_file = Rails.root.join("data", "world", "achievements.yml")

    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      next
    end

    data = YAML.load_file(yaml_file)
    achievements_data = data["achievements"]
    created = updated = 0

    achievements_data.each do |attrs|
      achievement = GridAchievement.find_or_initialize_by(slug: attrs["slug"])
      was_new = achievement.new_record?

      achievement.assign_attributes(
        name: attrs["name"],
        description: attrs["description"],
        badge_icon: attrs["badge_icon"],
        trigger_type: attrs["trigger_type"],
        trigger_data: attrs["trigger_data"] || {},
        xp_reward: attrs["xp_reward"] || 0,
        hidden: attrs["hidden"] || false
      )

      if achievement.changed?
        achievement.save!
        was_new ? (created += 1) : (updated += 1)
        puts "  #{was_new ? "✓ Created" : "↻ Updated"}: #{achievement.name}"
      end
    end

    puts "Achievements: #{created} created, #{updated} updated, #{GridAchievement.count} total"
  end

  desc "Load shop listings from YAML"
  task shop_listings: :environment do
    puts "\n--- Loading Shop Listings ---"
    yaml_file = Rails.root.join("data", "world", "shop_listings.yml")

    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      next
    end

    data = YAML.load_file(yaml_file)
    listings_data = data["shop_listings"]
    created = updated = 0

    listings_data.each do |attrs|
      room = GridRoom.find_by(slug: attrs["room_slug"])
      unless room
        puts "  ✗ Room not found: #{attrs["room_slug"]}"
        next
      end

      mob = GridMob.find_by(name: attrs["vendor_name"], grid_room: room)
      unless mob
        puts "  ✗ Vendor not found: #{attrs["vendor_name"]} in #{attrs["room_slug"]}"
        next
      end

      listing = GridShopListing.find_or_initialize_by(name: attrs["name"], grid_mob: mob)
      was_new = listing.new_record?

      base_price = attrs["base_price"]
      sell_price = attrs["sell_price"] || (base_price / 2.0).ceil

      listing.assign_attributes(
        description: attrs["description"],
        item_type: attrs["item_type"],
        rarity: attrs["rarity"],
        base_price: base_price,
        sell_price: sell_price,
        stock: attrs["max_stock"],
        max_stock: attrs["max_stock"],
        restock_amount: attrs["restock_amount"] || 1,
        restock_interval_hours: attrs["restock_interval_hours"] || mob.restock_interval_hours,
        next_restock_at: Time.current + (attrs["restock_interval_hours"] || mob.restock_interval_hours).hours,
        active: attrs.fetch("active", true),
        rotation_pool: attrs.fetch("rotation_pool", false),
        min_clearance: attrs["min_clearance"] || 0,
        properties: attrs["properties"] || {}
      )

      if listing.changed?
        listing.save!
        was_new ? (created += 1) : (updated += 1)
        puts "  #{was_new ? "✓ Created" : "↻ Updated"}: #{listing.name} (#{mob.name})"
      end
    end

    puts "Shop Listings: #{created} created, #{updated} updated, #{GridShopListing.count} total"
  end

  desc "Load key playlists from YAML"
  task key_playlists: :environment do
    puts "\n--- Loading Key Playlists ---"
    yaml_file = Rails.root.join("data", "playlists", "key_playlists.yml")
    yaml_file = Rails.root.join("data", "playlists.yml") unless File.exist?(yaml_file)

    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      next
    end

    data = YAML.load_file(yaml_file)
    playlists_data = data["playlists"]
    created = updated = 0

    playlists_data.each do |attrs|
      owner = GridHackr.find_by(hackr_alias: attrs["owner"])
      radio_station = attrs["radio_station"].present? ? RadioStation.find_by(slug: attrs["radio_station"]) : nil

      playlist = Playlist.find_or_initialize_by(name: attrs["name"])
      was_new = playlist.new_record?

      playlist.assign_attributes(
        description: attrs["description"],
        grid_hackr: owner,
        is_public: attrs["is_public"] || false
      )

      if playlist.changed? || was_new
        playlist.save!
        was_new ? (created += 1) : (updated += 1)
        puts "  #{was_new ? "✓ Created" : "↻ Updated"}: #{playlist.name}"
      end

      # Sync radio station link
      if radio_station
        RadioStationPlaylist.find_or_create_by!(
          radio_station: radio_station,
          playlist: playlist
        )
        puts "    → Linked to radio station: #{radio_station.name}"
      else
        # Remove stale radio station links for this playlist
        playlist.radio_station_playlists.destroy_all
      end

      # Sync tracks
      if attrs["tracks"].present?
        desired_tracks = []
        attrs["tracks"].each do |track_ref|
          artist_slug, track_slug = track_ref.split("/")
          artist = Artist.find_by(slug: artist_slug)
          track = artist&.tracks&.find_by(slug: track_slug)

          if track
            desired_tracks << track
          else
            puts "    ✗ Track not found: #{track_ref}"
          end
        end

        desired_track_ids = desired_tracks.map(&:id).to_set

        # Remove stale tracks
        playlist.playlist_tracks.each do |pt|
          unless desired_track_ids.include?(pt.track_id)
            pt.destroy!
            puts "    - Removed stale track from playlist"
          end
        end

        # Add/update track positions
        desired_tracks.each_with_index do |track, index|
          pt = PlaylistTrack.find_or_initialize_by(playlist: playlist, track: track)
          pt.position = index + 1
          pt.save! if pt.new_record? || pt.changed?
        end
        puts "    → Synced #{desired_tracks.size} tracks"
      else
        # No tracks specified — clear any existing
        removed = playlist.playlist_tracks.destroy_all.size
        puts "    - Removed #{removed} stale tracks" if removed > 0
      end
    end

    puts "Key Playlists: #{created} created, #{updated} updated, #{Playlist.count} total"
  end

  desc "Load codex entries from YAML"
  task codex: :environment do
    puts "\n--- Loading Codex Entries ---"
    yaml_file = Rails.root.join("data", "content", "codex.yml")

    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      next
    end

    data = YAML.load_file(yaml_file)
    entries_data = data["codex_entries"]
    created = updated = 0

    entries_data.each do |attrs|
      entry = CodexEntry.find_or_initialize_by(slug: attrs["slug"])
      was_new = entry.new_record?

      entry.assign_attributes(
        name: attrs["name"],
        entry_type: attrs["entry_type"],
        summary: attrs["summary"],
        content: attrs["content"],
        published: attrs["published"] || false,
        position: attrs["position"],
        metadata: attrs["metadata"]
      )

      if entry.changed? || attrs["metadata"].present?
        entry.save!
        was_new ? (created += 1) : (updated += 1)
        puts "  #{was_new ? "✓ Created" : "↻ Updated"}: #{entry.name} (#{entry.entry_type})"
      end
    end

    puts "Codex Entries: #{created} created, #{updated} updated, #{CodexEntry.count} total"
  end

  desc "Load hackr logs from YAML"
  task hackr_logs: :environment do
    puts "\n--- Loading Hackr Logs ---"
    yaml_file = Rails.root.join("data", "content", "hackr_logs.yml")

    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      next
    end

    data = YAML.load_file(yaml_file)
    logs_data = data["hackr_logs"]
    created = updated = 0

    logs_data.each do |attrs|
      grid_hackr = GridHackr.find_by(hackr_alias: attrs["author"])
      unless grid_hackr
        puts "  ✗ Author not found: #{attrs["author"]}"
        next
      end

      log = HackrLog.find_or_initialize_by(slug: attrs["slug"])
      was_new = log.new_record?

      # Parse lore date (subtract 100 years for database storage)
      published_at = nil
      if attrs["lore_date"].present?
        lore_time = Time.zone.parse(attrs["lore_date"])
        published_at = lore_time - 100.years
      end

      log.assign_attributes(
        grid_hackr: grid_hackr,
        title: attrs["title"],
        body: attrs["body"],
        timeline: attrs["timeline"] || "2120s",
        published: true,
        published_at: published_at
      )

      if log.changed?
        log.save!
        was_new ? (created += 1) : (updated += 1)
        puts "  #{was_new ? "✓ Created" : "↻ Updated"}: #{log.title}"
      end
    end

    puts "Hackr Logs: #{created} created, #{updated} updated, #{HackrLog.count} total"
  end

  desc "Load wire (pulses and echoes) from YAML"
  task wire: :environment do
    puts "\n--- Loading Wire (Pulses & Echoes) ---"
    yaml_file = Rails.root.join("data", "content", "wire.yml")

    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      next
    end

    data = YAML.load_file(yaml_file)
    pulse_slugs = {}
    created_pulses = created_echoes = 0

    # Load pulses
    puts "  Loading pulses..."
    data["pulses"]&.each do |attrs|
      author = GridHackr.find_by(hackr_alias: attrs["author"])
      unless author
        puts "    ✗ Author not found: #{attrs["author"]}"
        next
      end

      pulse = Pulse.find_or_initialize_by(grid_hackr: author, content: attrs["content"])

      if pulse.new_record?
        # Calculate timestamp
        pulsed_at = Time.current
        pulsed_at -= attrs["days_ago"].days if attrs["days_ago"]
        pulsed_at -= attrs["hours_ago"].hours if attrs["hours_ago"]
        pulsed_at += attrs["hours_offset"].hours if attrs["hours_offset"]
        pulsed_at += attrs["minutes_offset"].minutes if attrs["minutes_offset"]

        pulse.assign_attributes(
          pulsed_at: pulsed_at,
          is_seed: true,
          signal_dropped: attrs["signal_dropped"] || false
        )

        if attrs["signal_dropped"]
          dropped_at = Time.current
          dropped_at -= attrs["signal_dropped_hours_ago"].hours if attrs["signal_dropped_hours_ago"]
          pulse.signal_dropped_at = dropped_at
        end

        # Handle parent pulse (threading)
        if attrs["parent_slug"].present? && pulse_slugs[attrs["parent_slug"]]
          pulse.parent_pulse = pulse_slugs[attrs["parent_slug"]]
        end

        pulse.save!
        created_pulses += 1
        puts "    ✓ Created pulse: #{attrs["content"].truncate(50)}"
      end

      pulse_slugs[attrs["slug"]] = pulse if attrs["slug"].present?
    end

    # Load echoes
    puts "  Loading echoes..."
    data["echoes"]&.each do |attrs|
      pulse = pulse_slugs[attrs["pulse_slug"]]
      hackr = GridHackr.find_by(hackr_alias: attrs["hackr"])

      unless pulse && hackr
        puts "    ✗ Pulse or hackr not found: #{attrs["pulse_slug"]} / #{attrs["hackr"]}"
        next
      end

      echo = Echo.find_or_initialize_by(pulse: pulse, grid_hackr: hackr)

      if echo.new_record?
        echoed_at = Time.current
        echoed_at -= attrs["days_ago"].days if attrs["days_ago"]
        echoed_at -= attrs["hours_ago"].hours if attrs["hours_ago"]
        echoed_at += attrs["hours_offset"].hours if attrs["hours_offset"]
        echoed_at += attrs["minutes_offset"].minutes if attrs["minutes_offset"]

        echo.assign_attributes(
          echoed_at: echoed_at,
          is_seed: true
        )
        echo.save!
        created_echoes += 1
      end
    end

    puts "Wire: #{created_pulses} pulses created, #{created_echoes} echoes created"
  end

  desc "Load overlay elements from YAML"
  task overlay_elements: :environment do
    puts "\n--- Loading Overlay Elements ---"
    yaml_file = Rails.root.join("data", "overlays", "elements.yml")

    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      next
    end

    data = YAML.load_file(yaml_file)
    elements_data = data["elements"]
    created = updated = 0

    elements_data.each do |attrs|
      element = OverlayElement.find_or_initialize_by(slug: attrs["slug"])
      was_new = element.new_record?

      element.assign_attributes(
        name: attrs["name"],
        element_type: attrs["element_type"]
      )

      if element.changed?
        element.save!
        was_new ? (created += 1) : (updated += 1)
        puts "  #{was_new ? "✓ Created" : "↻ Updated"}: #{element.name}"
      end
    end

    puts "Overlay Elements: #{created} created, #{updated} updated, #{OverlayElement.count} total"
  end

  desc "Load overlay tickers from YAML"
  task overlay_tickers: :environment do
    puts "\n--- Loading Overlay Tickers ---"
    yaml_file = Rails.root.join("data", "overlays", "tickers.yml")

    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      next
    end

    data = YAML.load_file(yaml_file)
    tickers_data = data["tickers"]
    created = updated = 0

    tickers_data.each do |attrs|
      ticker = OverlayTicker.find_or_initialize_by(slug: attrs["slug"])
      was_new = ticker.new_record?

      ticker.assign_attributes(
        name: attrs["name"],
        content: attrs["content"],
        direction: attrs["direction"],
        speed: attrs["speed"],
        active: attrs["active"]
      )

      if ticker.changed?
        ticker.save!
        was_new ? (created += 1) : (updated += 1)
        puts "  #{was_new ? "✓ Created" : "↻ Updated"}: #{ticker.name}"
      end
    end

    puts "Overlay Tickers: #{created} created, #{updated} updated, #{OverlayTicker.count} total"
  end

  desc "Load overlay lower thirds from YAML"
  task overlay_lower_thirds: :environment do
    puts "\n--- Loading Overlay Lower Thirds ---"
    yaml_file = Rails.root.join("data", "overlays", "lower_thirds.yml")

    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      next
    end

    data = YAML.load_file(yaml_file)
    lower_thirds_data = data["lower_thirds"]
    created = updated = 0

    lower_thirds_data.each do |attrs|
      lt = OverlayLowerThird.find_or_initialize_by(slug: attrs["slug"])
      was_new = lt.new_record?

      lt.assign_attributes(
        name: attrs["name"],
        primary_text: attrs["primary_text"],
        secondary_text: attrs["secondary_text"],
        active: attrs["active"]
      )

      if lt.changed?
        lt.save!
        was_new ? (created += 1) : (updated += 1)
        puts "  #{was_new ? "✓ Created" : "↻ Updated"}: #{lt.name}"
      end
    end

    puts "Overlay Lower Thirds: #{created} created, #{updated} updated, #{OverlayLowerThird.count} total"
  end

  desc "Load overlay scenes from YAML"
  task overlay_scenes: :environment do
    puts "\n--- Loading Overlay Scenes ---"
    yaml_file = Rails.root.join("data", "overlays", "scenes.yml")

    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      next
    end

    data = YAML.load_file(yaml_file)
    scenes_data = data["scenes"]
    created = updated = 0

    scenes_data.each do |attrs|
      scene = OverlayScene.find_or_initialize_by(slug: attrs["slug"])
      was_new = scene.new_record?

      scene.assign_attributes(
        name: attrs["name"],
        scene_type: attrs["scene_type"],
        width: attrs["width"],
        height: attrs["height"]
      )

      if scene.changed?
        scene.save!
        was_new ? (created += 1) : (updated += 1)
        puts "  #{was_new ? "✓ Created" : "↻ Updated"}: #{scene.name}"
      end
    end

    puts "Overlay Scenes: #{created} created, #{updated} updated, #{OverlayScene.count} total"
  end

  desc "Load overlay scene elements from YAML"
  task overlay_scene_elements: :environment do
    puts "\n--- Loading Overlay Scene Elements ---"
    yaml_file = Rails.root.join("data", "overlays", "scene_elements.yml")

    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      next
    end

    data = YAML.load_file(yaml_file)
    scene_elements_data = data["scene_elements"]
    created = updated = 0

    scene_elements_data.each do |attrs|
      scene = OverlayScene.find_by(slug: attrs["scene_slug"])
      element = OverlayElement.find_by(slug: attrs["element_slug"])

      unless scene && element
        puts "  ✗ Scene or element not found: #{attrs["scene_slug"]} / #{attrs["element_slug"]}"
        next
      end

      se = OverlaySceneElement.find_or_initialize_by(
        overlay_scene: scene,
        overlay_element: element
      )
      was_new = se.new_record?

      se.assign_attributes(
        x: attrs["x"],
        y: attrs["y"],
        width: attrs["width"],
        height: attrs["height"],
        z_index: attrs["z_index"]
      )

      if se.changed?
        se.save!
        was_new ? (created += 1) : (updated += 1)
        puts "  #{was_new ? "✓ Created" : "↻ Updated"}: #{element.name} in #{scene.name}"
      end
    end

    puts "Overlay Scene Elements: #{created} created, #{updated} updated, #{OverlaySceneElement.count} total"
  end

  desc "Load overlay scene groups from YAML"
  task overlay_scene_groups: :environment do
    puts "\n--- Loading Overlay Scene Groups ---"
    yaml_file = Rails.root.join("data", "overlays", "scene_groups.yml")

    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      next
    end

    data = YAML.load_file(yaml_file)
    groups_data = data["scene_groups"] || []

    if groups_data.empty?
      puts "  No scene groups defined"
      next
    end

    created = updated = 0
    groups_data.each do |attrs|
      group = OverlaySceneGroup.find_or_initialize_by(slug: attrs["slug"])
      was_new = group.new_record?

      group.assign_attributes(
        name: attrs["name"],
        description: attrs["description"]
      )

      if group.changed?
        group.save!
        was_new ? (created += 1) : (updated += 1)
        puts "  #{was_new ? "✓ Created" : "↻ Updated"}: #{group.name}"
      end

      # Sync scenes in group
      scene_slugs = attrs["scenes"] || []
      desired_scenes = scene_slugs.filter_map { |slug| OverlayScene.find_by(slug: slug) }
      desired_scene_ids = desired_scenes.map(&:id).to_set

      existing = group.overlay_scene_group_scenes.includes(:overlay_scene).to_a
      existing_scene_ids = existing.map(&:overlay_scene_id).to_set

      # Remove stale
      existing.each do |sgs|
        unless desired_scene_ids.include?(sgs.overlay_scene_id)
          sgs.destroy!
          puts "    - Removed scene: #{sgs.overlay_scene.name}"
        end
      end

      # Add/update positions
      desired_scenes.each_with_index do |scene, index|
        sgs = OverlaySceneGroupScene.find_or_initialize_by(
          overlay_scene_group: group,
          overlay_scene: scene
        )
        sgs.position = index + 1
        if sgs.new_record? || sgs.changed?
          sgs.save!
          puts "    + Added scene: #{scene.name}" if !existing_scene_ids.include?(scene.id)
        end
      end
    end

    puts "Overlay Scene Groups: #{created} created, #{updated} updated"
  end

  desc "Load redirects from YAML"
  task redirects: :environment do
    puts "\n--- Loading Redirects ---"
    yaml_file = Rails.root.join("data", "system", "redirects.yml")

    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      next
    end

    data = YAML.load_file(yaml_file)
    mirror_groups = data["mirrors"] || []
    created = updated = 0

    # Build mirror lookup: primary_domain => [mirror_domains]
    mirror_map = {}
    mirror_groups.each do |group|
      mirror_map[group["primary"]] = group["domains"]
    end

    # Flatten domain-grouped redirects and expand mirrors
    expanded = []
    data["redirects"].each do |domain, entries|
      entries.each do |entry|
        expanded << entry.merge("domain" => domain)
        mirror_map[domain]&.each do |mirror_domain|
          expanded << entry.merge("domain" => mirror_domain)
        end
      end
    end

    expanded.each do |attrs|
      redirect = Redirect.find_or_initialize_by(
        domain: attrs["domain"],
        path: attrs["path"]
      )
      was_new = redirect.new_record?

      redirect.destination_url = attrs["destination_url"]

      if redirect.changed?
        redirect.save!
        was_new ? (created += 1) : (updated += 1)
        puts "  #{was_new ? "✓ Created" : "↻ Updated"}: #{attrs["domain"]}#{attrs["path"]} → #{attrs["destination_url"]}"
      end
    end

    puts "Redirects: #{created} created, #{updated} updated, #{Redirect.count} total"
  end

  desc "Load vidz (VODs/streams) from YAML"
  task vidz: :environment do
    puts "\n--- Loading Vidz ---"
    yaml_file = Rails.root.join("data", "vidz.yml")

    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      next
    end

    data = YAML.load_file(yaml_file)
    vidz_data = data["vidz"] || []

    if vidz_data.empty?
      puts "  No vidz entries found"
      next
    end

    created = updated = skipped = 0

    vidz_data.each do |attrs|
      artist = Artist.find_by("LOWER(name) = ?", attrs["artist"].to_s.downcase)
      unless artist
        puts "  ✗ Artist not found: #{attrs["artist"]}"
        skipped += 1
        next
      end

      started_at = attrs["started_at"].present? ? Time.parse(attrs["started_at"]) : nil
      ended_at = attrs["ended_at"].present? ? Time.parse(attrs["ended_at"]) : nil

      # Pre-convert YouTube URL to embed format to match what the model stores
      # (HackrStream.before_validation converts watch/live URLs to embed URLs)
      vod_url = DataLoaderHelpers.youtube_embed_url(attrs["vod_url"])

      stream = HackrStream.find_or_initialize_by(vod_url: vod_url, artist: artist)
      was_new = stream.new_record?

      live_url = DataLoaderHelpers.youtube_embed_url(attrs["live_url"])

      stream.assign_attributes(
        title: attrs["title"],
        live_url: live_url,
        track_slug: attrs["track_slug"],
        is_live: false,
        started_at: started_at,
        ended_at: ended_at
      )

      if was_new
        stream.save!
        created += 1
        puts "  ✓ Created: #{stream.title} (#{artist.name})"
      elsif stream.changed?
        stream.save!
        updated += 1
        puts "  ↻ Updated: #{stream.title} (#{artist.name})"
      end
    rescue => e
      puts "  ✗ Error processing '#{attrs["title"]}': #{e.message}"
      skipped += 1
    end

    puts "Vidz: #{created} created, #{updated} updated, #{skipped} skipped, #{HackrStream.count} total"
  end

  desc "Create TCP Livestream Archive playlist from tracks with audio"
  task livestream_archive: :environment do
    puts "\n--- Loading Livestream Archive Playlist ---"

    xeraen = GridHackr.find_by(hackr_alias: "XERAEN")
    unless xeraen
      puts "  ✗ XERAEN hackr not found (run data:hackrs first)"
      next
    end

    thecyberpulse = Artist.find_by(slug: "thecyberpulse")
    unless thecyberpulse
      puts "  ✗ The.CyberPul.se artist not found (run data:catalog first)"
      next
    end

    livestream_archive = thecyberpulse.releases.find_by(slug: "livestream-archive")
    unless livestream_archive
      puts "  ✗ Livestream Archive release not found (run data:catalog first)"
      next
    end

    tracks_with_audio = livestream_archive.tracks
      .joins(:audio_file_attachment)
      .order(:track_number, :title)

    if tracks_with_audio.empty?
      puts "  ⚠ No tracks with audio found in Livestream Archive album"
      puts "  Run data:audio to attach audio files first"
      next
    end

    puts "  Found #{tracks_with_audio.count} tracks with audio"

    playlist = xeraen.playlists.find_or_initialize_by(name: "TCP Livestream Archive")
    was_new = playlist.new_record?

    playlist.assign_attributes(
      description: "Archived recordings from The.CyberPul.se live trans-temporal broadcasts.",
      is_public: false
    )

    if playlist.changed? || was_new
      playlist.save!
      puts "  #{was_new ? "✓ Created" : "↻ Updated"}: #{playlist.name}"
    end

    # Add tracks to playlist
    added = 0
    tracks_with_audio.each do |track|
      pt = PlaylistTrack.find_or_initialize_by(playlist: playlist, track: track)
      if pt.new_record?
        pt.save!
        added += 1
        puts "    + Added: #{track.title}"
      end
    end

    # Link to radio station
    radio_station = RadioStation.find_by(slug: "thecyberpulse")
    if radio_station
      RadioStationPlaylist.find_or_create_by!(radio_station: radio_station, playlist: playlist)
      puts "  → Linked to radio station: #{radio_station.name}"
    else
      puts "  ⚠ Radio station 'thecyberpulse' not found"
    end

    puts "Livestream Archive: #{added} tracks added, #{playlist.playlist_tracks.count} total in playlist"
  end

  # === Audio Sideloading ===
  desc "Sideload audio files from local imports/ directory or S3 bucket"
  task audio: :environment do
    dry_run = ENV["DRY_RUN"] == "true"
    cleanup = ENV["CLEANUP"] == "true"
    s3_bucket = ENV["S3_BUCKET"]
    s3_prefix = ENV["S3_PREFIX"] || "audio/"

    audio_extensions = %w[.mp3 .ogg .wav .flac .m4a .aac]
    attached_count = 0
    skipped_count = 0
    error_count = 0
    not_found_count = 0

    # Helper to attach audio to a track
    attach_audio = lambda do |track, filename, io, ext, source_desc|
      if track.audio_file.attached?
        puts "    ⊘ Already attached: #{track.title}"
        skipped_count += 1
        return false
      end

      if dry_run
        puts "    → Would attach: #{filename} → #{track.title}"
        attached_count += 1
        return true
      end

      begin
        track.audio_file.attach(
          io: io,
          filename: filename,
          content_type: Marcel::MimeType.for(extension: ext)
        )
        attached_count += 1
        puts "    ✓ Attached: #{filename} → #{track.title}"
        true
      rescue => e
        error_count += 1
        puts "    ✗ Error attaching #{filename}: #{e.message}"
        false
      end
    end

    # Helper to parse artist/track from file path
    parse_file_path = lambda do |key, artist_slug_from_dir = nil|
      filename = File.basename(key)
      ext = File.extname(filename).downcase
      return nil unless audio_extensions.include?(ext)

      base = File.basename(filename, ".*")

      if artist_slug_from_dir
        # Subdirectory structure: {artist-slug}/{track-slug}.ext
        {artist_slug: artist_slug_from_dir, track_slug: base, filename: filename, ext: ext}
      elsif base.include?("--")
        # Flat structure: {artist-slug}--{track-slug}.ext
        parts = base.split("--", 2)
        {artist_slug: parts[0], track_slug: parts[1], filename: "#{parts[1]}#{ext}", ext: ext}
      end
    end

    if s3_bucket
      # S3 mode
      require "aws-sdk-s3"

      puts "\n" + "=" * 80
      puts "SIDELOADING AUDIO FILES FROM S3"
      puts "  Bucket: #{s3_bucket}"
      puts "  Prefix: #{s3_prefix}"
      puts "=" * 80 + "\n"

      if dry_run
        puts "  ⚠ DRY RUN MODE - no files will be attached\n"
      end

      s3 = Aws::S3::Client.new
      artists_seen = {}

      # List all objects under the prefix
      s3.list_objects_v2(bucket: s3_bucket, prefix: s3_prefix).each do |response|
        response.contents.each do |object|
          key = object.key
          relative_path = key.sub(/^#{Regexp.escape(s3_prefix)}/, "")
          next if relative_path.empty? || relative_path.end_with?("/")

          # Determine structure from path depth
          path_parts = relative_path.split("/")

          parsed = if path_parts.length == 2
            # Subdirectory structure: {artist-slug}/{track-slug}.ext
            parse_file_path.call(path_parts[1], path_parts[0])
          elsif path_parts.length == 1
            # Flat structure: {artist-slug}--{track-slug}.ext
            parse_file_path.call(path_parts[0])
          end

          next unless parsed

          normalized_slug = parsed[:artist_slug].tr("_", "-")
          artist = Artist.find_by(slug: normalized_slug)
          unless artist
            unless artists_seen[normalized_slug]
              puts "  ⚠ Artist not found: #{normalized_slug}"
              artists_seen[normalized_slug] = true
            end
            not_found_count += 1
            next
          end

          unless artists_seen[artist.slug]
            puts "\n  Processing artist: #{artist.name} (#{artist.slug})"
            artists_seen[artist.slug] = true
          end

          track = artist.tracks.find_by(slug: parsed[:track_slug])
          unless track
            puts "    ✗ Track not found: #{parsed[:track_slug]}"
            not_found_count += 1
            next
          end

          # Stream from S3 and attach
          io = if dry_run
            StringIO.new
          else
            s3.get_object(bucket: s3_bucket, key: key).body
          end

          attach_audio.call(track, parsed[:filename], io, parsed[:ext], key)
        end
      end
    else
      # Local mode
      puts "\n" + "=" * 80
      puts "SIDELOADING AUDIO FILES FROM imports/"
      puts "=" * 80 + "\n"

      imports_dir = Rails.root.join("imports")

      unless Dir.exist?(imports_dir)
        puts "  ✗ Import directory not found: #{imports_dir}"
        puts "  Create it and add audio files with one of these structures:"
        puts "    imports/{artist-slug}/{track-slug}.mp3"
        puts "    imports/{artist-slug}--{track-slug}.ogg"
        puts "\n  Or use S3_BUCKET to load from S3 instead."
        next
      end

      if dry_run
        puts "  ⚠ DRY RUN MODE - no files will be attached\n"
      end

      # Process subdirectory structure: imports/{artist-slug}/{track-slug}.ext
      Dir.glob(imports_dir.join("*")).each do |artist_dir|
        next unless File.directory?(artist_dir)

        artist_slug = File.basename(artist_dir).tr("_", "-")
        artist = Artist.find_by(slug: artist_slug)

        unless artist
          puts "  ⚠ Artist not found for directory: #{artist_slug}"
          next
        end

        puts "\n  Processing artist: #{artist.name} (#{artist_slug})"

        Dir.glob(File.join(artist_dir, "*")).each do |file_path|
          next if File.directory?(file_path)

          parsed = parse_file_path.call(file_path, artist_slug)
          next unless parsed

          track = artist.tracks.find_by(slug: parsed[:track_slug])

          unless track
            puts "    ✗ Track not found: #{parsed[:track_slug]}"
            not_found_count += 1
            next
          end

          if attach_audio.call(track, parsed[:filename], File.open(file_path), parsed[:ext], file_path)
            if cleanup && !dry_run
              File.delete(file_path)
              puts "      → Cleaned up source file"
            end
          end
        end
      end

      # Process flat structure: imports/{artist-slug}--{track-slug}.ext
      Dir.glob(imports_dir.join("*")).each do |file_path|
        next if File.directory?(file_path)

        parsed = parse_file_path.call(file_path)
        next unless parsed

        artist = Artist.find_by(slug: parsed[:artist_slug].tr("_", "-"))
        unless artist
          puts "  ✗ Artist not found: #{parsed[:artist_slug]} (from #{File.basename(file_path)})"
          not_found_count += 1
          next
        end

        track = artist.tracks.find_by(slug: parsed[:track_slug])
        unless track
          puts "  ✗ Track not found: #{parsed[:track_slug]} for artist #{artist.name}"
          not_found_count += 1
          next
        end

        if attach_audio.call(track, parsed[:filename], File.open(file_path), parsed[:ext], file_path)
          if cleanup && !dry_run
            File.delete(file_path)
            puts "    → Cleaned up source file"
          end
        end
      end
    end

    puts "\n" + "=" * 80
    puts "AUDIO SIDELOAD SUMMARY"
    puts "=" * 80
    puts "  Source: #{s3_bucket ? "s3://#{s3_bucket}/#{s3_prefix}" : "imports/"}"
    puts "  Attached: #{attached_count}#{" (dry run)" if dry_run}"
    puts "  Skipped (already attached): #{skipped_count}"
    puts "  Not found (artist/track): #{not_found_count}"
    puts "  Errors: #{error_count}"
    puts "\nUsage:"
    puts "  rails data:audio                           # From local imports/"
    puts "  S3_BUCKET=bucket rails data:audio          # From S3 (prefix: audio/)"
    puts "  S3_PREFIX=path/ S3_BUCKET=bucket rails ... # Custom S3 prefix"
    puts "\nOptions:"
    puts "  DRY_RUN=true   - Preview without attaching"
    puts "  CLEANUP=true   - Delete local source files after attaching (ignored for S3)"
    puts "=" * 80 + "\n"
  end
end

# Helper module for data loading utilities
module DataLoaderHelpers
  module_function

  # Normalize a value for serialized JSON columns to prevent spurious dirty tracking.
  # YAML loads Ruby objects that may differ in structure from what ActiveRecord
  # deserializes from the database (e.g., HashWithIndifferentAccess vs Hash,
  # symbol keys vs string keys). Round-tripping through JSON ensures consistent
  # comparison so that `changed?` only fires on real changes.
  def normalize_json(value)
    return nil if value.nil?
    JSON.parse(JSON.generate(value))
  end

  # Convert YouTube watch/live URLs to embed format, matching
  # HackrStream's before_validation conversion. This ensures
  # find_or_initialize_by matches existing DB records.
  def youtube_embed_url(url)
    return url if url.blank?

    [
      /youtube\.com\/watch\?v=([a-zA-Z0-9_-]{11})/,
      /youtu\.be\/([a-zA-Z0-9_-]{11})/,
      /youtube\.com\/live\/([a-zA-Z0-9_-]{11})/
    ].each do |pattern|
      if (match = url.match(pattern))
        return "https://www.youtube.com/embed/#{match[1]}"
      end
    end

    url
  end

  def parse_date(date_value)
    return nil if date_value.blank?
    return nil if %w[TBA TBD].include?(date_value.to_s.strip)
    Date.parse(date_value.to_s)
  rescue ArgumentError
    nil
  end

  def attach_cover_image(release, cover_image_path, artist_slug)
    filename = File.basename(cover_image_path)
    legacy_slug = artist_slug.tr("-", "_")
    possible_paths = [
      Rails.root.join("data", artist_slug, filename),
      Rails.root.join("data", artist_slug, "covers", filename),
      Rails.root.join("data", artist_slug, "images", filename),
      Rails.root.join("data", legacy_slug, filename),
      Rails.root.join("data", legacy_slug, "covers", filename),
      Rails.root.join("data", legacy_slug, "images", filename),
      Rails.root.join("data", cover_image_path)
    ]

    cover_path = possible_paths.find { |path| File.exist?(path) }
    return unless cover_path

    if release.cover_image.attached?
      source_mtime = File.mtime(cover_path)
      blob_created = release.cover_image.blob.created_at
      return if source_mtime <= blob_created
      release.cover_image.purge
      puts "    → Re-attaching cover (source newer): #{filename}"
    end

    release.cover_image.attach(
      io: File.open(cover_path),
      filename: filename,
      content_type: "image/jpeg"
    )
    puts "    → Attached cover image: #{filename}"
  end
end
