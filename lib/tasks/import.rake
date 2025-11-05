namespace :import do
  desc "Import all data from Sinatra app (artists, tracks, redirects)"
  task all: :environment do
    puts "\n" + "=" * 80
    puts "IMPORTING ALL DATA FROM SINATRA APP"
    puts "=" * 80 + "\n"

    Rake::Task["import:artists"].invoke
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
      {name: "The.CyberPul.se", slug: "thecyberpulse"},
      {name: "XERAEN", slug: "xeraen"}
    ]

    created_count = 0
    updated_count = 0

    artists_data.each do |artist_data|
      artist = Artist.find_or_initialize_by(slug: artist_data[:slug])

      if artist.new_record?
        artist.name = artist_data[:name]
        artist.save!
        created_count += 1
        puts "  ✓ Created artist: #{artist.name} (#{artist.slug})"
      elsif artist.name != artist_data[:name]
        artist.update!(name: artist_data[:name])
        updated_count += 1
        puts "  ↻ Updated artist: #{artist.name} (#{artist.slug})"
      else
        puts "  ✓ Artist exists: #{artist.name} (#{artist.slug})"
      end
    end

    puts "\nArtist import summary:"
    puts "  Created: #{created_count}"
    puts "  Updated: #{updated_count}"
    puts "  Total:   #{Artist.count}"
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

          # Prepare track attributes
          track_attributes = {
            title: yaml_data["title"],
            album: yaml_data["album"],
            album_type: yaml_data["album_type"],
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

  desc "Clear all imported data (DANGEROUS - use with caution)"
  task clear: :environment do
    print "\n⚠️  WARNING: This will delete ALL artists, tracks, and redirects. Continue? (y/N): "
    response = $stdin.gets.chomp.downcase

    if response == "y"
      puts "\nClearing data..."
      Track.destroy_all
      puts "  ✓ Deleted all tracks"
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
