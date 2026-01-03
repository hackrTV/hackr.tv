namespace :import do
  desc "Import all data from YAML files with file attachments"
  task from_yaml: :environment do
    puts "\n" + "=" * 80
    puts "IMPORTING ALL DATA FROM YAML FILES"
    puts "=" * 80 + "\n"

    Rake::Task["import:yaml_artists"].invoke
    Rake::Task["import:yaml_albums"].invoke
    Rake::Task["import:yaml_tracks"].invoke
    Rake::Task["import:yaml_vidz"].invoke
    Rake::Task["import:redirects"].invoke
    Rake::Task["import:radio_stations"].invoke

    puts "\n" + "=" * 80
    puts "IMPORT COMPLETE"
    puts "=" * 80 + "\n"
  end

  desc "Import all data from Sinatra app (artists, albums, tracks, redirects)"
  task all: :environment do
    puts "\n" + "=" * 80
    puts "IMPORTING ALL DATA FROM SINATRA APP"
    puts "=" * 80 + "\n"

    Rake::Task["import:artists"].invoke
    Rake::Task["import:albums"].invoke
    Rake::Task["import:tracks"].invoke
    Rake::Task["import:redirects"].invoke

    puts "\n" + "=" * 80
    puts "IMPORT COMPLETE"
    puts "=" * 80 + "\n"
  end

  desc "Import artists from Sinatra app"
  task artists: :environment do
    puts "\n--- Importing Artists ---\n"

    artists_data = [
      {name: "The.CyberPul.se", slug: "thecyberpulse", genre: "Synthwave/Cyberpunk"},
      {name: "XERAEN", slug: "xeraen", genre: "Industrial/Dark Synth"}
    ]

    created_count = 0
    updated_count = 0

    artists_data.each do |artist_data|
      artist = Artist.find_or_initialize_by(slug: artist_data[:slug])

      if artist.new_record?
        artist.name = artist_data[:name]
        artist.genre = artist_data[:genre]
        artist.save!
        created_count += 1
        puts "  ✓ Created artist: #{artist.name} (#{artist.slug}) - #{artist.genre}"
      elsif artist.name != artist_data[:name] || artist.genre != artist_data[:genre]
        artist.update!(name: artist_data[:name], genre: artist_data[:genre])
        updated_count += 1
        puts "  ↻ Updated artist: #{artist.name} (#{artist.slug}) - #{artist.genre}"
      else
        puts "  ✓ Artist exists: #{artist.name} (#{artist.slug}) - #{artist.genre}"
      end
    end

    puts "\nArtist import summary:"
    puts "  Created: #{created_count}"
    puts "  Updated: #{updated_count}"
    puts "  Total:   #{Artist.count}"
  end

  desc "Import albums from track YAML files (must run after artists)"
  task albums: :environment do
    puts "\n--- Importing Albums from Track YAML ---\n"

    source_dir = File.join(Rails.root, "data")

    unless Dir.exist?(source_dir)
      puts "  ✗ Error: Source directory #{source_dir} not found"
      next
    end

    created_count = 0
    updated_count = 0
    artists = ["xeraen", "thecyberpulse"]
    albums_seen = {}

    artists.each do |artist_slug|
      artist_dir = File.join(source_dir, artist_slug)
      next unless Dir.exist?(artist_dir)

      artist = Artist.find_by(slug: artist_slug)
      unless artist
        puts "  ✗ Artist not found: #{artist_slug} (run 'rails import:artists' first)"
        next
      end

      puts "\n  Processing artist: #{artist.name} (#{artist.slug})"

      tracks_path = File.join(artist_dir, "trackz")
      next unless Dir.exist?(tracks_path)

      # First pass: collect unique albums from all tracks
      Dir.glob(File.join(tracks_path, "*.yml")).each do |file_path|
        yaml_data = YAML.load_file(file_path)
        album_name = yaml_data["album"]
        next if album_name.blank?

        album_key = [artist.id, album_name]
        next if albums_seen.key?(album_key)

        albums_seen[album_key] = {
          album_type: yaml_data["album_type"],
          release_date: yaml_data["release_date"]
        }
      rescue => e
        puts "    ✗ Error reading #{file_path}: #{e.message}"
      end

      # Create albums
      albums_seen.each do |(artist_id, album_name), album_data|
        slug = album_name.downcase
          .gsub(/[^a-z0-9\s-]/, "")
          .gsub(/\s+/, "-").squeeze("-")
          .strip

        album = artist.albums.find_or_initialize_by(slug: slug)
        was_new = album.new_record?

        album.assign_attributes(
          name: album_name,
          album_type: album_data[:album_type]
        )

        # Handle release_date
        if album_data[:release_date]
          begin
            album.release_date = Date.parse(album_data[:release_date])
          rescue ArgumentError
            album.release_date = nil
          end
        end

        if album.changed?
          if album.save
            if was_new
              created_count += 1
              puts "    ✓ Created album: #{album.name}"
            else
              updated_count += 1
              puts "    ↻ Updated album: #{album.name}"
            end
          else
            puts "    ✗ Failed to save album #{album_name}: #{album.errors.full_messages.join(", ")}"
          end
        else
          puts "    ✓ Album exists: #{album.name}"
        end
      end
    end

    puts "\nAlbum import summary:"
    puts "  Created: #{created_count}"
    puts "  Updated: #{updated_count}"
    puts "  Total:   #{Album.count}"
  end

  desc "Import track data from YAML files in data directory"
  task tracks: :environment do
    puts "\n--- Importing Tracks from YAML ---\n"

    source_dir = File.join(Rails.root, "data")

    unless Dir.exist?(source_dir)
      puts "  ✗ Error: Source directory #{source_dir} not found"
      puts "  Please ensure the data directory exists at the project root"
      next
    end

    created_count = 0
    updated_count = 0
    skipped_count = 0
    error_count = 0

    artists = ["xeraen", "thecyberpulse"]

    artists.each do |artist_slug|
      artist_dir = File.join(source_dir, artist_slug)
      next unless Dir.exist?(artist_dir)

      # Find artist
      artist = Artist.find_by(slug: artist_slug)
      unless artist
        puts "  ✗ Artist not found: #{artist_slug} (run 'rails import:artists' first)"
        next
      end

      puts "\n  Processing artist: #{artist.name} (#{artist.slug})"

      # Import tracks
      tracks_path = File.join(artist_dir, "trackz")
      next unless Dir.exist?(tracks_path)

      Dir.glob(File.join(tracks_path, "*.yml")).each do |file_path|
        slug = File.basename(file_path, ".yml")

        begin
          yaml_data = YAML.load_file(file_path)

          track = artist.tracks.find_or_initialize_by(slug: slug)
          was_new_record = track.new_record?

          # Find the album for this track
          album_name = yaml_data["album"]
          if album_name.blank?
            puts "    ✗ Skipping #{slug}: no album specified"
            next
          end

          album_slug = album_name.downcase
            .gsub(/[^a-z0-9\s-]/, "")
            .gsub(/\s+/, "-").squeeze("-")
            .strip

          album = artist.albums.find_by(slug: album_slug)
          unless album
            puts "    ✗ Album not found for #{slug}: #{album_name} (run 'rails import:albums' first)"
            next
          end

          # Prepare track attributes
          track_attributes = {
            title: yaml_data["title"],
            album: album,
            track_number: yaml_data["track_number"],
            duration: yaml_data["duration"],
            cover_image: yaml_data["cover_image"],
            featured: yaml_data["featured"] || false,
            streaming_links: yaml_data["streaming_links"],
            videos: yaml_data["videos"],
            lyrics: yaml_data["lyrics"]
          }

          # Handle release_date (might be a date or string like "TBA Release")
          if yaml_data["release_date"]
            begin
              track_attributes[:release_date] = Date.parse(yaml_data["release_date"])
            rescue ArgumentError
              # If it's not a valid date (e.g., "TBA Release"), leave it nil
              track_attributes[:release_date] = nil
            end
          end

          track.assign_attributes(track_attributes)

          if track.changed?
            if track.save
              if was_new_record
                created_count += 1
                puts "    ✓ Created: #{track.title}"
              else
                updated_count += 1
                puts "    ↻ Updated: #{track.title}"
              end
            else
              error_count += 1
              puts "    ✗ Failed to save #{slug}: #{track.errors.full_messages.join(", ")}"
            end
          else
            skipped_count += 1
            puts "    ✓ No changes: #{track.title}"
          end
        rescue => e
          error_count += 1
          puts "    ✗ Error processing #{file_path}: #{e.message}"
        end
      end
    end

    puts "\nTrack import summary:"
    puts "  Created: #{created_count}"
    puts "  Updated: #{updated_count}"
    puts "  Skipped: #{skipped_count} (no changes)"
    puts "  Errors:  #{error_count}"
    puts "  Total:   #{Track.count}"
  end

  desc "Import redirect data from Sinatra app constants (idempotent)"
  task redirects: :environment do
    puts "\n--- Importing Redirects ---\n"

    created_count = 0
    updated_count = 0
    skipped_count = 0

    # Ashlinn redirects
    ashlinn_redirects = {
      "/" => "https://youtube.com/AshlinnSnow"
    }

    # Xeraen redirects (applicable to multiple domains)
    xeraen_redirects = {
      "/" => "/xeraen",
      "/git" => "https://github.com/xeraen",
      "/github" => "https://github.com/xeraen",
      "/twitter" => "https://x.com/xeraen",
      "/x" => "https://x.com/xeraen",
      "/youtube" => "https://youtube.com/@xeraen"
    }

    # Sector X redirects
    sector_x_redirects = {
      "/" => "/sector/x"
    }

    # Map domains to their redirect sets
    redirect_mappings = [
      # Ashlinn redirects
      {domain: "ashlinn.net", redirects: ashlinn_redirects},

      # XERAEN/Rockerboy redirects
      {domain: "xeraen.com", redirects: xeraen_redirects},
      {domain: "xeraen.net", redirects: xeraen_redirects},
      {domain: "rockerboy.net", redirects: xeraen_redirects},
      {domain: "rockerboy.stream", redirects: xeraen_redirects},

      # Sector X redirects
      {domain: "sectorx.media", redirects: sector_x_redirects}
    ]

    redirect_mappings.each do |mapping|
      domain = mapping[:domain]
      redirects = mapping[:redirects]

      redirects.each do |path, destination_url|
        redirect = Redirect.find_or_initialize_by(domain: domain, path: path)

        if redirect.new_record?
          redirect.destination_url = destination_url
          redirect.save!
          created_count += 1
          puts "  ✓ Created: #{domain}#{path} → #{destination_url}"
        elsif redirect.destination_url != destination_url
          redirect.update!(destination_url: destination_url)
          updated_count += 1
          puts "  ↻ Updated: #{domain}#{path} → #{destination_url}"
        else
          skipped_count += 1
          puts "  ✓ Exists: #{domain}#{path} → #{destination_url}"
        end
      end
    end

    puts "\nRedirect import summary:"
    puts "  Created: #{created_count}"
    puts "  Updated: #{updated_count}"
    puts "  Skipped: #{skipped_count} (no changes)"
    puts "  Total:   #{Redirect.count}"
  end

  desc "Import artists from data/artists.yml"
  task yaml_artists: :environment do
    puts "\n--- Importing Artists from YAML ---\n"

    yaml_file = Rails.root.join("data", "artists.yml")
    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      return
    end

    yaml_data = YAML.load_file(yaml_file)
    artists_data = yaml_data["artists"]

    created_count = 0
    updated_count = 0

    artists_data.each do |artist_data|
      artist = Artist.find_or_initialize_by(slug: artist_data["slug"])
      artist_type = artist_data["artist_type"] || "band"

      if artist.new_record?
        artist.name = artist_data["name"]
        artist.genre = artist_data["genre"]
        artist.artist_type = artist_type
        artist.save!
        created_count += 1
        puts "  ✓ Created artist: #{artist.name} (#{artist.slug}) - #{artist.genre} [#{artist_type}]"
      elsif artist.name != artist_data["name"] || artist.genre != artist_data["genre"] || artist.artist_type != artist_type
        artist.update!(name: artist_data["name"], genre: artist_data["genre"], artist_type: artist_type)
        updated_count += 1
        puts "  ↻ Updated artist: #{artist.name} (#{artist.slug}) - #{artist.genre} [#{artist_type}]"
      else
        puts "  ✓ Artist exists: #{artist.name} (#{artist.slug}) - #{artist.genre} [#{artist.artist_type}]"
      end
    end

    puts "\nArtist import summary:"
    puts "  Created: #{created_count}"
    puts "  Updated: #{updated_count}"
    puts "  Total:   #{Artist.count}"
  end

  desc "Import albums from data/albums.yml with cover images"
  task yaml_albums: :environment do
    puts "\n--- Importing Albums from YAML ---\n"

    yaml_file = Rails.root.join("data", "albums.yml")
    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      return
    end

    yaml_data = YAML.load_file(yaml_file)
    albums_data = yaml_data["albums"]

    created_count = 0
    updated_count = 0
    skipped_count = 0
    cover_attached_count = 0
    cover_missing_count = 0

    albums_data.each do |album_data|
      # Skip if album data is incomplete
      next unless album_data["title"].present? && album_data["slug"].present?

      # Find artist
      artist = Artist.find_by(name: album_data["artist"])
      unless artist
        puts "  ✗ Artist not found: #{album_data["artist"]}"
        skipped_count += 1
        next
      end

      # Find or create album
      album = Album.find_or_initialize_by(artist: artist, slug: album_data["slug"])

      # Parse release date
      release_date = nil
      if album_data["release_date"].present? &&
          !["TBA", "TBD", ""].include?(album_data["release_date"].to_s.strip)
        begin
          release_date = Date.parse(album_data["release_date"])
        rescue ArgumentError
          # Invalid date, assign random future date
          release_date = nil
        end
      end

      # release_date remains nil for TBA albums (will sort to end with NULLS LAST)

      if album.new_record?
        album.name = album_data["title"]
        album.album_type = album_data["album_type"]
        album.release_date = release_date
        album.description = album_data["description"]
        album.save!
        created_count += 1
        puts "  ✓ Created album: #{album.name} (#{artist.name})"
      else
        needs_update = false
        needs_update = true if album.name != album_data["title"]
        needs_update = true if album.album_type != album_data["album_type"]
        needs_update = true if album.release_date != release_date
        needs_update = true if album.description != album_data["description"]

        if needs_update
          album.update!(
            name: album_data["title"],
            album_type: album_data["album_type"],
            release_date: release_date,
            description: album_data["description"]
          )
          updated_count += 1
          puts "  ↻ Updated album: #{album.name} (#{artist.name})"
        else
          puts "  ✓ Album exists: #{album.name} (#{artist.name})"
        end
      end

      # Attach cover image if specified and not already attached
      if album_data["cover_image"].present? && !album.cover_image.attached?
        # Try multiple possible paths
        filename = File.basename(album_data["cover_image"])
        possible_paths = [
          Rails.root.join("data", artist.slug, filename),
          Rails.root.join("data", artist.slug, "covers", filename),
          Rails.root.join("data", artist.slug, "images", filename),
          Rails.root.join("data", album_data["cover_image"])  # Fallback to full path
        ]

        cover_path = possible_paths.find { |path| File.exist?(path) }

        if cover_path
          album.cover_image.attach(
            io: File.open(cover_path),
            filename: filename
          )
          cover_attached_count += 1
          puts "    → Attached cover image: #{filename}"
        else
          cover_missing_count += 1
          puts "    ⚠ Cover image not found in: data/#{artist.slug}/"
        end
      end
    end

    puts "\nAlbum import summary:"
    puts "  Created: #{created_count}"
    puts "  Updated: #{updated_count}"
    puts "  Skipped: #{skipped_count}"
    puts "  Cover images attached: #{cover_attached_count}"
    puts "  Cover images missing: #{cover_missing_count}"
    puts "  Total albums: #{Album.count}"
  end

  desc "Import tracks from data/tracks.yml and individual artist YAML files with audio files"
  task yaml_tracks: :environment do
    puts "\n--- Importing Tracks from YAML ---\n"

    created_count = 0
    updated_count = 0
    skipped_count = 0
    error_count = 0
    audio_attached_count = 0
    audio_missing_count = 0

    all_track_data = []

    # Load from main tracks.yml if it exists (handles multiple YAML documents)
    main_tracks_file = Rails.root.join("data", "tracks.yml")
    if File.exist?(main_tracks_file)
      puts "  Loading tracks from tracks.yml..."
      YAML.load_stream(File.read(main_tracks_file)).each do |document|
        if document.is_a?(Array)
          all_track_data.concat(document)
        elsif document.is_a?(Hash)
          all_track_data << document
        end
      end
    end

    # Load from individual artist track YAML files
    Artist.find_each do |artist|
      trackz_dir = Rails.root.join("data", artist.slug, "trackz")
      next unless Dir.exist?(trackz_dir)

      Dir.glob(trackz_dir.join("*.yml")).each do |track_file|
        YAML.load_stream(File.read(track_file)).each do |track_data|
          next unless track_data.is_a?(Hash)
          # Set slug from filename if not present (only for single-track files)
          track_data["slug"] ||= File.basename(track_file, ".yml")
          all_track_data << track_data
        end
      rescue => e
        puts "  ⚠ Error loading #{track_file}: #{e.message}"
      end
    end

    puts "  Found #{all_track_data.size} tracks to process\n"

    all_track_data.each do |track_data|
      # Skip tracks with skip flag
      if track_data["skip"]
        puts "  ⊘ Skipped track: #{track_data["title"]} (skip flag set)"
        skipped_count += 1
        next
      end

      # Find artist (case-insensitive)
      artist = Artist.find_by("LOWER(name) = ?", track_data["artist"].to_s.downcase)
      unless artist
        puts "  ✗ Artist not found for track '#{track_data["title"]}': #{track_data["artist"]}"
        skipped_count += 1
        next
      end

      # Find album (case-insensitive)
      album = artist.albums.find_by("LOWER(name) = ?", track_data["album"].to_s.downcase)
      unless album
        puts "  ✗ Album not found for track '#{track_data["title"]}': #{track_data["album"]} (artist: #{artist.name})"
        skipped_count += 1
        next
      end

      # Find or create track
      track = artist.tracks.find_or_initialize_by(slug: track_data["slug"])

      # Parse release date
      release_date = nil
      if track_data["release_date"].present? && track_data["release_date"] != "TBA" && track_data["release_date"] != "TBA Release"
        begin
          release_date = Date.parse(track_data["release_date"])
        rescue ArgumentError
          # Invalid date, keep as nil
        end
      end

      # Process lyrics - remove section markers (lines starting with [)
      lyrics = nil
      if track_data["lyrics"].present?
        lyrics = track_data["lyrics"].split("\n").reject { |line| line.strip.start_with?("[") }.join("\n").strip
        lyrics = nil if lyrics.blank?
      end

      # Auto-assign track number if not specified
      track_number = track_data["track_number"]
      if track_number.nil?
        # Get the max track number for this album, default to 0 if none exist
        max_track_number = album.tracks.maximum(:track_number) || 0
        track_number = max_track_number + 1
      end

      # Prepare track attributes
      track_attributes = {
        title: track_data["title"],
        album: album,
        track_number: track_number,
        release_date: release_date,
        duration: (track_data["duration"] == "TBA") ? nil : track_data["duration"],
        featured: track_data["featured"] || false,
        show_in_pulse_vault: track_data.key?("show_in_pulse_vault") ? track_data["show_in_pulse_vault"] : true,
        streaming_links: track_data["streaming_links"]&.compact&.presence,
        videos: track_data["videos"]&.compact&.presence,
        lyrics: lyrics
      }

      if track.new_record?
        track.assign_attributes(track_attributes)
        track.save!
        created_count += 1
        puts "  ✓ Created track: #{track.title} (#{artist.name} - #{album.name})"
      else
        # Check if update is needed
        needs_update = false
        track_attributes.each do |key, value|
          if track.send(key) != value
            needs_update = true
            break
          end
        end

        if needs_update
          track.update!(track_attributes)
          updated_count += 1
          puts "  ↻ Updated track: #{track.title} (#{artist.name} - #{album.name})"
        else
          puts "  ✓ Track exists: #{track.title} (#{artist.name} - #{album.name})"
        end
      end

      # Attach audio file if specified and not already attached
      if track_data["audio_file"].present? && !track.audio_file.attached?
        # Try multiple possible paths in artist directory
        filename = File.basename(track_data["audio_file"])
        possible_paths = [
          Rails.root.join("data", artist.slug, filename),
          Rails.root.join("data", artist.slug, "audio", filename),
          Rails.root.join("data", artist.slug, "trackz", filename),
          Rails.root.join("data", artist.slug, "tracks", filename),
          Rails.root.join("data", track_data["audio_file"])  # Fallback to full path
        ]

        audio_path = possible_paths.find { |path| File.exist?(path) }

        if audio_path
          track.audio_file.attach(
            io: File.open(audio_path),
            filename: filename
          )
          audio_attached_count += 1
          puts "    → Attached audio file: #{filename}"
        else
          audio_missing_count += 1
          puts "    ⚠ Audio file not found in: data/#{artist.slug}/"
        end
      end
    rescue => e
      error_count += 1
      puts "  ✗ Error processing track '#{track_data["title"]}': #{e.message}"
    end

    puts "\nTrack import summary:"
    puts "  Created: #{created_count}"
    puts "  Updated: #{updated_count}"
    puts "  Skipped: #{skipped_count}"
    puts "  Errors: #{error_count}"
    puts "  Audio files attached: #{audio_attached_count}"
    puts "  Audio files missing: #{audio_missing_count}"
    puts "  Total tracks: #{Track.count}"
  end

  desc "Import vidz/VODs from data/vidz.yml"
  task yaml_vidz: :environment do
    puts "\n--- Importing Vidz/VODs from YAML ---\n"

    yaml_file = Rails.root.join("data", "vidz.yml")
    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      next
    end

    yaml_data = YAML.load_file(yaml_file)
    vidz_data = yaml_data["vidz"] || []

    if vidz_data.empty?
      puts "  No vidz entries found in #{yaml_file}"
      puts "\nVidz import summary:"
      puts "  Created: 0"
      puts "  Updated: 0"
      puts "  Total:   #{HackrStream.count}"
      next
    end

    created_count = 0
    updated_count = 0
    skipped_count = 0

    vidz_data.each do |vid_data|
      # Find artist (case-insensitive)
      artist = Artist.find_by("LOWER(name) = ?", vid_data["artist"].to_s.downcase)
      unless artist
        puts "  ✗ Artist not found: #{vid_data["artist"]}"
        skipped_count += 1
        next
      end

      # Parse timestamps
      started_at = nil
      ended_at = nil

      if vid_data["started_at"].present?
        begin
          started_at = Time.parse(vid_data["started_at"])
        rescue ArgumentError
          puts "  ⚠ Invalid started_at for '#{vid_data["title"]}': #{vid_data["started_at"]}"
        end
      end

      if vid_data["ended_at"].present?
        begin
          ended_at = Time.parse(vid_data["ended_at"])
        rescue ArgumentError
          puts "  ⚠ Invalid ended_at for '#{vid_data["title"]}': #{vid_data["ended_at"]}"
        end
      end

      # Find existing by vod_url or create new
      stream = HackrStream.find_or_initialize_by(vod_url: vid_data["vod_url"], artist: artist)
      was_new_record = stream.new_record?

      stream.assign_attributes(
        title: vid_data["title"],
        live_url: vid_data["live_url"],
        is_live: false,
        started_at: started_at,
        ended_at: ended_at
      )

      if was_new_record
        stream.save!
        created_count += 1
        puts "  ✓ Created VOD: #{stream.title} (#{artist.name})"
      elsif stream.changed?
        stream.save!
        updated_count += 1
        puts "  ↻ Updated VOD: #{stream.title} (#{artist.name})"
      else
        puts "  ✓ VOD exists: #{stream.title} (#{artist.name})"
      end
    rescue => e
      puts "  ✗ Error processing '#{vid_data["title"]}': #{e.message}"
      skipped_count += 1
    end

    puts "\nVidz import summary:"
    puts "  Created: #{created_count}"
    puts "  Updated: #{updated_count}"
    puts "  Skipped: #{skipped_count}"
    puts "  Total:   #{HackrStream.count}"
  end

  desc "Import radio stations from YAML to database"
  task radio_stations: :environment do
    puts "\n--- Importing Radio Stations from YAML ---\n"

    yaml_file = Rails.root.join("data", "radio_stations.yml")
    unless File.exist?(yaml_file)
      puts "  ✗ File not found: #{yaml_file}"
      return
    end

    data = YAML.load_file(yaml_file)
    created_count = 0
    updated_count = 0

    data["stations"].each_with_index do |station_data, index|
      station = RadioStation.find_or_initialize_by(slug: station_data["slug"])
      was_new_record = station.new_record?

      station.assign_attributes(
        name: station_data["name"],
        description: station_data["description"],
        genre: station_data["genre"],
        color: station_data["color"],
        stream_url: station_data["stream_url"],
        position: index
      )

      if was_new_record
        station.save!
        created_count += 1
        puts "  ✓ Created radio station: #{station.name} (position: #{station.position})"
      elsif station.changed?
        station.save!
        updated_count += 1
        puts "  ↻ Updated radio station: #{station.name} (position: #{station.position})"
      else
        puts "  ✓ Radio station exists: #{station.name}"
      end
    end

    puts "\nRadio station import summary:"
    puts "  Created: #{created_count}"
    puts "  Updated: #{updated_count}"
    puts "  Total:   #{RadioStation.count}"
  end

  desc "Sideload audio files from local imports/ directory or S3 bucket"
  task sideload_audio: :environment do
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
      puts "SIDELOADING AUDIO FILES FROM /rails/imports"
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
    puts "SIDELOAD SUMMARY"
    puts "=" * 80
    puts "  Source: #{s3_bucket ? "s3://#{s3_bucket}/#{s3_prefix}" : "imports/"}"
    puts "  Attached: #{attached_count}#{" (dry run)" if dry_run}"
    puts "  Skipped (already attached): #{skipped_count}"
    puts "  Not found (artist/track): #{not_found_count}"
    puts "  Errors: #{error_count}"
    puts "\nUsage:"
    puts "  rails import:sideload_audio                      # From local imports/"
    puts "  S3_BUCKET=bucket rails import:sideload_audio     # From S3 (prefix: audio/)"
    puts "  S3_PREFIX=path/ S3_BUCKET=bucket rails ...       # Custom S3 prefix"
    puts "\nOptions:"
    puts "  DRY_RUN=true   - Preview without attaching"
    puts "  CLEANUP=true   - Delete local source files after attaching (ignored for S3)"
    puts "=" * 80 + "\n"
  end

  desc "Clear all imported data (DANGEROUS - use with caution)"
  task clear: :environment do
    print "\n⚠️  WARNING: This will delete ALL artists, albums, tracks, and redirects. Continue? (y/N): "
    response = $stdin.gets.chomp.downcase

    if response == "y"
      puts "\nClearing data..."
      Track.destroy_all
      puts "  ✓ Deleted all tracks"
      Album.destroy_all
      puts "  ✓ Deleted all albums"
      Artist.destroy_all
      puts "  ✓ Deleted all artists"
      Redirect.destroy_all
      puts "  ✓ Deleted all redirects"
      puts "\nData cleared successfully."
    else
      puts "\nCancelled. No data was deleted."
    end
  end
end
