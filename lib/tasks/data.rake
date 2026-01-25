# Unified Data Loading System
# YAML files are the single source of truth for all seeded content
#
# Import Order (respecting dependencies):
# 1. artists           (no deps)
# 2. albums            (depends on artists)
# 3. tracks            (depends on albums)
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
# 18. overlay_elements (no deps)
# 19. overlay_tickers  (no deps)
# 20. overlay_lower_thirds (no deps)
# 21. overlay_scenes   (no deps)
# 22. overlay_scene_elements (depends on scenes, elements)
# 23. overlay_scene_groups (depends on scenes)
# 24. redirects        (no deps)

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
    Rake::Task["data:overlays"].invoke

    if ENV["S3_BUCKET"].present?
      puts "\n" + "-" * 80
      puts "S3_BUCKET detected - loading audio files..."
      puts "-" * 80 + "\n"
      Rake::Task["data:audio"].invoke
    end

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
  desc "Load catalog (artists, albums, tracks)"
  task catalog: [:artists, :albums, :tracks]

  desc "Load system data (hackrs, channels, radio stations, etc.)"
  task system: [:hackrs, :channels, :radio_stations, :zone_playlists, :redirects]

  desc "Load world data (factions, zones, rooms, etc.)"
  task world: [:factions, :zones, :rooms, :exits, :mobs, :items]

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
    Album.destroy_all
    Artist.destroy_all
    puts "All data cleared."
  end

  # === Individual Loaders ===

  desc "Load artists from YAML"
  task artists: :environment do
    puts "\n--- Loading Artists ---"
    yaml_file = Rails.root.join("data", "catalog", "artists.yml")
    yaml_file = Rails.root.join("data", "artists.yml") unless File.exist?(yaml_file)

    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      next
    end

    data = YAML.load_file(yaml_file)
    artists_data = data["artists"]
    created = updated = 0

    artists_data.each do |attrs|
      artist = Artist.find_or_initialize_by(slug: attrs["slug"])
      was_new = artist.new_record?

      artist.assign_attributes(
        name: attrs["name"],
        genre: attrs["genre"],
        artist_type: attrs["artist_type"] || "band"
      )

      if artist.changed?
        artist.save!
        was_new ? (created += 1) : (updated += 1)
        puts "  #{was_new ? "✓ Created" : "↻ Updated"}: #{artist.name}"
      end
    end

    puts "Artists: #{created} created, #{updated} updated, #{Artist.count} total"
  end

  desc "Load albums from YAML"
  task albums: :environment do
    puts "\n--- Loading Albums ---"
    yaml_file = Rails.root.join("data", "catalog", "albums.yml")
    yaml_file = Rails.root.join("data", "albums.yml") unless File.exist?(yaml_file)

    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      next
    end

    data = YAML.load_file(yaml_file)
    albums_data = data["albums"]
    created = updated = skipped = 0

    albums_data.each do |attrs|
      next unless attrs["title"].present? && attrs["slug"].present?

      artist = Artist.find_by(slug: attrs["artist_slug"])
      unless artist
        puts "  ✗ Artist not found: #{attrs["artist_slug"]}"
        skipped += 1
        next
      end

      album = Album.find_or_initialize_by(artist: artist, slug: attrs["slug"])
      was_new = album.new_record?

      release_date = DataLoaderHelpers.parse_date(attrs["release_date"])

      album.assign_attributes(
        name: attrs["title"],
        album_type: attrs["album_type"],
        release_date: release_date,
        description: attrs["description"]
      )

      if album.changed?
        album.save!
        was_new ? (created += 1) : (updated += 1)
        puts "  #{was_new ? "✓ Created" : "↻ Updated"}: #{album.name} (#{artist.name})"
      end

      # Attach cover image if specified and not already attached
      DataLoaderHelpers.attach_cover_image(album, attrs["cover_image"], artist.slug) if attrs["cover_image"].present?
    end

    puts "Albums: #{created} created, #{updated} updated, #{skipped} skipped, #{Album.count} total"
  end

  desc "Load tracks from YAML"
  task tracks: :environment do
    puts "\n--- Loading Tracks ---"
    yaml_file = Rails.root.join("data", "catalog", "tracks.yml")
    yaml_file = Rails.root.join("data", "tracks.yml") unless File.exist?(yaml_file)

    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      next
    end

    data = YAML.load_file(yaml_file)
    tracks_data = data["tracks"]
    created = updated = skipped = 0

    tracks_data.each do |attrs|
      # Find album by slug, derive artist from album
      album = Album.find_by(slug: attrs["album_slug"])
      unless album
        puts "  ✗ Album not found: #{attrs["album_slug"]}"
        skipped += 1
        next
      end

      artist = album.artist
      track = artist.tracks.find_or_initialize_by(slug: attrs["slug"])
      was_new = track.new_record?

      track.assign_attributes(
        title: attrs["title"],
        album: album,
        track_number: attrs["track_number"],
        duration: attrs["duration"],
        cover_image: attrs["cover_image"],
        featured: attrs["featured"] || false,
        show_in_pulse_vault: attrs.fetch("show_in_pulse_vault", true),
        streaming_links: attrs["streaming_links"],
        videos: attrs["videos"],
        lyrics: attrs["lyrics"]
        # release_date inherited from album unless track-specific
      )

      if track.changed?
        track.save!
        was_new ? (created += 1) : (updated += 1)
        puts "  #{was_new ? "✓ Created" : "↻ Updated"}: #{track.title}"
      end
    end

    puts "Tracks: #{created} created, #{updated} updated, #{skipped} skipped, #{Track.count} total"
  end

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
        position: attrs["position"] || 0
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

      # Add tracks from artist
      if attrs["artist_tracks"].present?
        artist = Artist.find_by(slug: attrs["artist_tracks"])
        if artist
          artist.tracks.each_with_index do |track, index|
            ZonePlaylistTrack.find_or_create_by!(
              zone_playlist: playlist,
              track: track
            ) do |zpt|
              zpt.position = index + 1
            end
          end
          puts "    → Added #{artist.tracks.count} tracks from #{artist.name}"
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
        room_type: attrs["room_type"]
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
    created = 0

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

      if exit_record.new_record?
        exit_record.locked = attrs["locked"] || false
        exit_record.save!
        created += 1
        puts "  ✓ Created: #{from_room.name} -> #{attrs["direction"]} -> #{to_room.name}"
      end
    end

    puts "Exits: #{created} created, #{GridExit.count} total"
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
        dialogue_tree: attrs["dialogue_tree"]
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
    created = 0

    items_data.each do |attrs|
      room = GridRoom.find_by(slug: attrs["room_slug"])
      unless room
        puts "  ✗ Room not found: #{attrs["room_slug"]}"
        next
      end

      item = GridItem.find_or_initialize_by(name: attrs["name"], room: room)
      if item.new_record?
        item.assign_attributes(
          description: attrs["description"],
          item_type: attrs["item_type"]
        )
        item.save!
        created += 1
        puts "  ✓ Created: #{item.name}"
      end
    end

    puts "Items: #{created} created, #{GridItem.count} total"
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

      # Link to radio station if specified
      if radio_station
        RadioStationPlaylist.find_or_create_by!(
          radio_station: radio_station,
          playlist: playlist
        )
        puts "    → Linked to radio station: #{radio_station.name}"
      end

      # Add tracks
      if attrs["tracks"].present?
        attrs["tracks"].each_with_index do |track_ref, index|
          artist_slug, track_slug = track_ref.split("/")
          artist = Artist.find_by(slug: artist_slug)
          track = artist&.tracks&.find_by(slug: track_slug)

          if track
            PlaylistTrack.find_or_create_by!(playlist: playlist, track: track) do |pt|
              pt.position = index + 1
            end
          else
            puts "    ✗ Track not found: #{track_ref}"
          end
        end
        puts "    → Added #{attrs["tracks"].size} tracks"
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

      if entry.changed?
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
    created = 0

    elements_data.each do |attrs|
      element = OverlayElement.find_or_initialize_by(slug: attrs["slug"])
      if element.new_record?
        element.assign_attributes(
          name: attrs["name"],
          element_type: attrs["element_type"]
        )
        element.save!
        created += 1
        puts "  ✓ Created: #{element.name}"
      end
    end

    puts "Overlay Elements: #{created} created, #{OverlayElement.count} total"
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
    created = 0

    scenes_data.each do |attrs|
      scene = OverlayScene.find_or_initialize_by(slug: attrs["slug"])
      if scene.new_record?
        scene.assign_attributes(
          name: attrs["name"],
          scene_type: attrs["scene_type"],
          width: attrs["width"],
          height: attrs["height"]
        )
        scene.save!
        created += 1
        puts "  ✓ Created: #{scene.name}"
      end
    end

    puts "Overlay Scenes: #{created} created, #{OverlayScene.count} total"
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
    created = 0

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

      if se.new_record?
        se.assign_attributes(
          x: attrs["x"],
          y: attrs["y"],
          width: attrs["width"],
          height: attrs["height"],
          z_index: attrs["z_index"]
        )
        se.save!
        created += 1
        puts "  ✓ Created: #{element.name} in #{scene.name}"
      end
    end

    puts "Overlay Scene Elements: #{created} created, #{OverlaySceneElement.count} total"
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

    created = 0
    groups_data.each do |attrs|
      group = OverlaySceneGroup.find_or_initialize_by(slug: attrs["slug"])
      if group.new_record?
        group.assign_attributes(
          name: attrs["name"],
          description: attrs["description"]
        )
        group.save!
        created += 1
        puts "  ✓ Created: #{group.name}"

        # Add scenes to group
        attrs["scenes"]&.each_with_index do |scene_slug, index|
          scene = OverlayScene.find_by(slug: scene_slug)
          if scene
            OverlaySceneGroupScene.create!(
              overlay_scene_group: group,
              overlay_scene: scene,
              position: index + 1
            )
          end
        end
      end
    end

    puts "Overlay Scene Groups: #{created} created"
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
    redirects_data = data["redirects"]
    created = updated = 0

    redirects_data.each do |attrs|
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

          artist = Artist.find_by(slug: parsed[:artist_slug])
          unless artist
            unless artists_seen[parsed[:artist_slug]]
              puts "  ⚠ Artist not found: #{parsed[:artist_slug]}"
              artists_seen[parsed[:artist_slug]] = true
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

        artist_slug = File.basename(artist_dir)
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

        artist = Artist.find_by(slug: parsed[:artist_slug])
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

  def parse_date(date_value)
    return nil if date_value.blank?
    return nil if %w[TBA TBD].include?(date_value.to_s.strip)
    Date.parse(date_value.to_s)
  rescue ArgumentError
    nil
  end

  def attach_cover_image(album, cover_image_path, artist_slug)
    return if album.cover_image.attached?

    filename = File.basename(cover_image_path)
    possible_paths = [
      Rails.root.join("data", artist_slug, filename),
      Rails.root.join("data", artist_slug, "covers", filename),
      Rails.root.join("data", artist_slug, "images", filename),
      Rails.root.join("data", cover_image_path)
    ]

    cover_path = possible_paths.find { |path| File.exist?(path) }

    if cover_path
      album.cover_image.attach(
        io: File.open(cover_path),
        filename: filename
      )
      puts "    → Attached cover image: #{filename}"
    end
  end
end
