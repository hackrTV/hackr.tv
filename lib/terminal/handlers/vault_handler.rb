# frozen_string_literal: true

module Terminal
  module Handlers
    # Handler for Pulse Vault track listings
    class VaultHandler < BaseHandler
      ITEMS_PER_PAGE = 15

      def on_enter
        super
        @current_page = 1
        @filter = nil
        clear_screen
        display_banner
        display_tracks
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
          @filter = nil
          @current_page = 1
          display_tracks
        when "next", "n"
          @current_page += 1
          display_tracks
        when "prev", "p"
          @current_page = [@current_page - 1, 1].max
          display_tracks
        when "artist", "by"
          filter_by_artist(args)
        when "album", "on"
          filter_by_album(args)
        when "search", "find"
          search_tracks(args)
        when "view", "v"
          view_track(args)
        when "featured"
          show_featured
        when "help", "?"
          display_help
        else
          # Try as search
          search_tracks(input)
        end
      end

      def prompt
        renderer.colorize("vault> ", :amber)
      end

      def display_help
        println ""
        println renderer.header("PULSE VAULT COMMANDS", color: :amber)
        println ""
        println renderer.colorize("  Browsing:", :amber)
        println "    list              - Show all tracks"
        println "    next (n)          - Next page"
        println "    prev (p)          - Previous page"
        println "    artist <name>     - Filter by artist"
        println "    album <name>      - Filter by album"
        println "    search <query>    - Search tracks"
        println "    view <title>      - View track details"
        println "    featured          - Show featured tracks"
        println ""
        println renderer.colorize("  Other:", :amber)
        println "    back              - Return to main menu"
        println ""
      end

      private

      def display_banner
        banner = Art.banner(:vault)
        if banner.present?
          println renderer.colorize(banner, :amber)
        end
      end

      def display_tracks
        query = base_query
        query = apply_filter(query) if @filter

        total_count = query.count
        total_pages = (total_count.to_f / ITEMS_PER_PAGE).ceil
        @current_page = @current_page.clamp(1, [total_pages, 1].max)

        tracks = query
          .includes(:artist, :album)
          .limit(ITEMS_PER_PAGE)
          .offset((@current_page - 1) * ITEMS_PER_PAGE)

        println ""

        filter_display = @filter ? " (filtered)" : ""
        println renderer.divider("TRACKS#{filter_display}", width: 60, color: :amber)
        println ""

        if tracks.empty?
          println renderer.colorize("  No tracks found.", :gray)
        else
          # Header
          println "  #{renderer.colorize("TRACK".ljust(30), :gray)} #{renderer.colorize("ARTIST".ljust(20), :gray)} #{renderer.colorize("DUR", :gray)}"
          println renderer.divider(width: 60, color: :gray)

          tracks.each do |track|
            title = track.title.truncate(28)
            artist = track.artist.name.truncate(18)
            duration = format_duration(track.duration)
            featured = track.featured? ? renderer.colorize("*", :amber) : " "

            println "#{featured} #{renderer.colorize(title.ljust(29), :cyan)} #{renderer.colorize(artist.ljust(19), :purple)} #{renderer.colorize(duration, :gray)}"
          end
        end

        println ""
        println renderer.divider("Page #{@current_page}/#{total_pages} | #{total_count} tracks", width: 60, color: :gray)
        println ""
        println renderer.colorize("  [n]ext [p]rev [artist] <name> [album] <name> [search] <q> [back]", :gray)
        println ""
      end

      def base_query
        Track.visible_in_pulse_vault.order(Arel.sql("CASE WHEN artists.slug = 'the-cyberpulse' THEN 0 WHEN artists.slug = 'xeraen' THEN 1 ELSE 2 END, artists.name, tracks.title"))
          .joins(:artist)
      end

      def apply_filter(query)
        case @filter[:type]
        when :artist
          query.where("LOWER(artists.name) LIKE ? OR LOWER(artists.slug) LIKE ?", "%#{@filter[:value].downcase}%", "%#{@filter[:value].downcase}%")
        when :album
          query.joins(:album).where("LOWER(albums.name) LIKE ?", "%#{@filter[:value].downcase}%")
        when :search
          query.where("LOWER(tracks.title) LIKE ?", "%#{@filter[:value].downcase}%")
        else
          query
        end
      end

      def filter_by_artist(name)
        if name.blank?
          println renderer.colorize("Usage: artist <name>", :amber)
          return
        end

        @filter = {type: :artist, value: name}
        @current_page = 1
        display_tracks
      end

      def filter_by_album(name)
        if name.blank?
          println renderer.colorize("Usage: album <name>", :amber)
          return
        end

        @filter = {type: :album, value: name}
        @current_page = 1
        display_tracks
      end

      def search_tracks(query)
        if query.blank?
          println renderer.colorize("Usage: search <query>", :amber)
          return
        end

        @filter = {type: :search, value: query}
        @current_page = 1
        display_tracks
      end

      def view_track(title)
        if title.blank?
          println renderer.colorize("Usage: view <track title>", :amber)
          return
        end

        track = Track.where("LOWER(title) LIKE ?", "%#{title.downcase}%").first

        unless track
          println renderer.colorize("Track not found: #{title}", :red)
          return
        end

        display_track_details(track)
      end

      def display_track_details(track)
        println ""
        println renderer.double_line(width: 60, color: :cyan)
        println renderer.bold_color(track.title.upcase, :cyan)
        println renderer.colorize("by #{track.artist.name}", :purple)
        if track.album
          println renderer.colorize("from #{track.album.name}", :gray)
        end
        println renderer.double_line(width: 60, color: :cyan)

        println ""
        println renderer.key_value("Duration:", format_duration(track.duration))
        println renderer.key_value("Track #:", track.track_number.to_s) if track.track_number
        println renderer.key_value("Featured:", track.featured? ? "Yes" : "No")

        if track.release_date
          println renderer.key_value("Released:", track.release_date.strftime("%B %d, %Y"))
        end

        if track.lyrics.present?
          println ""
          println renderer.divider("LYRICS", width: 60, color: :amber)
          println ""
          println track.lyrics.truncate(500)
          if track.lyrics.length > 500
            println ""
            println renderer.colorize("  (truncated - view full lyrics at hackr.tv)", :gray)
          end
        end

        println ""
        println renderer.colorize("  Listen at hackr.tv/fm", :gray)
        println ""
      end

      def show_featured
        @filter = nil
        tracks = Track.where(featured: true).includes(:artist, :album).limit(20)

        println ""
        println renderer.divider("FEATURED TRACKS", width: 60, color: :amber)
        println ""

        if tracks.empty?
          println renderer.colorize("  No featured tracks.", :gray)
        else
          tracks.each do |track|
            duration = format_duration(track.duration)
            println "  #{renderer.colorize(track.title, :cyan)} - #{renderer.colorize(track.artist.name, :purple)} #{renderer.colorize(duration, :gray)}"
          end
        end

        println ""
      end

      def format_duration(duration)
        return "--:--" if duration.blank?
        duration.to_s
      end
    end
  end
end
