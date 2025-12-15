# frozen_string_literal: true

module Terminal
  module Handlers
    # Handler for hackr.fm band profiles
    class BandsHandler < BaseHandler
      def on_enter
        super
        clear_screen
        display_banner
        list_bands
      end

      def display
        @displayed = true
      end

      def handle(input)
        cmd, args = parse_command(input)

        case cmd
        when "back", "menu"
          go_back
        when "list", "l"
          list_bands
        when "view", "band", "v"
          show_band(args)
        when "album", "a"
          show_album(args)
        when "search", "find"
          search_bands(args)
        when "help", "?"
          display_help
        else
          # Try to interpret as a band name
          show_band(input)
        end
      end

      def prompt
        renderer.colorize("bands> ", :green)
      end

      def display_help
        println ""
        println renderer.header("HACKR.FM COMMANDS", color: :green)
        println ""
        println renderer.colorize("  Browsing:", :amber)
        println "    list              - Show all bands"
        println "    view <name>       - View band profile"
        println "    album <name>      - View album details"
        println "    search <query>    - Search bands"
        println ""
        println renderer.colorize("  Other:", :amber)
        println "    back              - Return to main menu"
        println ""
      end

      private

      def display_banner
        banner = Art.banner(:bands)
        if banner.present?
          println renderer.colorize(banner, :green)
        end
      end

      def list_bands
        bands = Artist.bands.order(:name)

        println ""
        println renderer.divider("BANDS ON THE NETWORK", width: 60, color: :green)
        println ""

        if bands.empty?
          println renderer.colorize("  No bands found.", :gray)
        else
          bands.each do |band|
            album_count = band.albums.count
            track_count = band.tracks.count
            genre = band.genre || "Unknown"

            println "  #{renderer.colorize(band.name, :cyan)}"
            println "    #{renderer.colorize(genre, :purple)} | #{album_count} album(s) | #{track_count} track(s)"
            println ""
          end
        end

        println renderer.divider("#{bands.count} bands total", width: 60, color: :gray)
        println ""
        println renderer.colorize("  Type band name to view profile, or [back] for menu", :gray)
        println ""
      end

      def show_band(name)
        if name.blank?
          println renderer.colorize("Usage: view <band name>", :amber)
          return
        end

        band = Artist.bands.where("LOWER(name) = ? OR LOWER(slug) = ?", name.downcase, name.downcase).first

        unless band
          println renderer.colorize("Band not found: #{name}", :red)
          println renderer.colorize("Try 'search #{name}' or 'list' to see all bands.", :gray)
          return
        end

        display_band(band)
      end

      def display_band(band)
        println ""
        println renderer.double_line(width: 60, color: :green)
        println renderer.bold_color(band.name.upcase, :cyan)
        println renderer.colorize(band.genre || "Unknown Genre", :purple)
        println renderer.double_line(width: 60, color: :green)

        # Discography
        albums = band.albums.order(release_date: :desc)

        println ""
        if albums.any?
          println renderer.colorize("  DISCOGRAPHY:", :amber)
          println ""

          albums.each do |album|
            year = album.release_date&.year || "TBA"
            album_type = album.album_type&.upcase || "ALBUM"
            println "  #{renderer.colorize(album.name, :cyan)} #{renderer.colorize("(#{year})", :gray)} #{renderer.colorize("[#{album_type}]", :purple)}"

            # Show tracks for this album
            album.tracks.order(:track_number).each do |track|
              track_num = track.track_number&.to_s&.rjust(2, "0") || "--"
              duration = format_duration(track.duration)
              featured = track.featured? ? renderer.colorize(" [FEATURED]", :amber) : ""
              println "    #{renderer.colorize(track_num, :gray)}. #{track.title} #{renderer.colorize(duration, :gray)}#{featured}"
            end
            println ""
          end
        else
          println renderer.colorize("  No albums yet.", :gray)
          println ""
        end

        # Stats
        total_tracks = band.tracks.count
        println renderer.divider("#{total_tracks} tracks total", width: 60, color: :gray)
        println ""
        println renderer.colorize("  Listen at hackr.tv/fm or #{band.slug}.hackr.tv", :gray)
        println ""
      end

      def show_album(name)
        if name.blank?
          println renderer.colorize("Usage: album <album name>", :amber)
          return
        end

        album = Album.where("LOWER(name) LIKE ?", "%#{name.downcase}%").first

        unless album
          println renderer.colorize("Album not found: #{name}", :red)
          return
        end

        println ""
        println renderer.double_line(width: 60, color: :cyan)
        println renderer.bold_color(album.name.upcase, :cyan)
        println renderer.colorize("by #{album.artist.name}", :purple)
        if album.release_date
          println renderer.colorize("Released: #{album.release_date.strftime("%B %d, %Y")}", :gray)
        end
        println renderer.double_line(width: 60, color: :cyan)

        if album.description.present?
          println ""
          println album.description
        end

        println ""
        println renderer.colorize("  TRACKS:", :amber)
        println ""

        album.tracks.order(:track_number).each do |track|
          track_num = track.track_number&.to_s&.rjust(2, "0") || "--"
          duration = format_duration(track.duration)
          println "  #{renderer.colorize(track_num, :gray)}. #{renderer.colorize(track.title, :cyan)} #{renderer.colorize(duration, :gray)}"
        end

        println ""
      end

      def search_bands(query)
        if query.blank?
          println renderer.colorize("Usage: search <query>", :amber)
          return
        end

        bands = Artist.bands.where("LOWER(name) LIKE ? OR LOWER(genre) LIKE ?", "%#{query.downcase}%", "%#{query.downcase}%")

        println ""
        println renderer.divider("SEARCH: #{query}", width: 60, color: :green)
        println ""

        if bands.empty?
          println renderer.colorize("  No bands found matching '#{query}'.", :gray)
        else
          bands.each do |band|
            println "  #{renderer.colorize(band.name, :cyan)} - #{renderer.colorize(band.genre || "Unknown", :purple)}"
          end
        end

        println ""
      end

      def format_duration(duration)
        return "" if duration.blank?
        duration.to_s
      end
    end
  end
end
