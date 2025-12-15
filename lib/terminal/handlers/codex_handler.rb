# frozen_string_literal: true

module Terminal
  module Handlers
    # Handler for The Codex lore wiki
    class CodexHandler < BaseHandler
      include CodexHelper

      ENTRY_TYPES = %w[person organization event location technology faction item].freeze

      def on_enter
        super
        clear_screen
        display_banner
        display_categories
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
          display_categories
        when "type", "t"
          list_by_type(args)
        when "search", "find"
          search_entries(args)
        when "read", "r"
          read_entry(args)
        when "recent"
          show_recent
        when "help", "?"
          display_help
        else
          # Try to interpret as a slug or entry name
          read_entry(input)
        end
      end

      def prompt
        renderer.colorize("codex> ", :purple)
      end

      def display_help
        println ""
        println renderer.header("CODEX COMMANDS", color: :purple)
        println ""
        println renderer.colorize("  Browsing:", :amber)
        println "    list              - Show entry categories"
        println "    type <category>   - List entries by type"
        println "    search <query>    - Search entries"
        println "    read <slug>       - Read an entry"
        println "    recent            - Recently updated entries"
        println ""
        println renderer.colorize("  Categories:", :amber)
        ENTRY_TYPES.each do |type|
          println "    #{type}"
        end
        println ""
        println renderer.colorize("  Other:", :amber)
        println "    back              - Return to main menu"
        println ""
      end

      private

      def display_banner
        banner = Art.banner(:codex)
        if banner.present?
          println renderer.colorize(banner, :purple)
        end
      end

      def display_categories
        println ""
        println renderer.divider("ENTRY TYPES", width: 60, color: :purple)
        println ""

        ENTRY_TYPES.each do |type|
          count = CodexEntry.published.where(entry_type: type).count
          type_color = entry_type_color(type)
          println "  #{renderer.colorize(type.titleize.ljust(15), type_color)} #{renderer.colorize("(#{count} entries)", :gray)}"
        end

        total = CodexEntry.published.count
        println ""
        println renderer.divider("#{total} entries total", width: 60, color: :gray)
        println ""
        println renderer.colorize("  [type <name>] [search <query>] [read <slug>] [back]", :gray)
        println ""
      end

      def list_by_type(type_name)
        if type_name.blank?
          println renderer.colorize("Usage: type <category>", :amber)
          return
        end

        type = type_name.downcase.singularize
        unless ENTRY_TYPES.include?(type)
          println renderer.colorize("Unknown type: #{type_name}", :red)
          println renderer.colorize("Available: #{ENTRY_TYPES.join(", ")}", :gray)
          return
        end

        entries = CodexEntry.published.where(entry_type: type).order(:name)

        println ""
        println renderer.divider(type.titleize.pluralize.upcase, width: 60, color: entry_type_color(type))
        println ""

        if entries.empty?
          println renderer.colorize("  No entries found.", :gray)
        else
          entries.each do |entry|
            println "  #{renderer.colorize(entry.name, :cyan)} #{renderer.colorize("(#{entry.slug})", :gray)}"
          end
        end

        println ""
      end

      def search_entries(query)
        if query.blank?
          println renderer.colorize("Usage: search <query>", :amber)
          return
        end

        entries = CodexEntry.published
          .where("name LIKE ? OR summary LIKE ?", "%#{query}%", "%#{query}%")
          .order(:name)
          .limit(20)

        println ""
        println renderer.divider("SEARCH: #{query}", width: 60, color: :cyan)
        println ""

        if entries.empty?
          println renderer.colorize("  No entries found matching '#{query}'.", :gray)
        else
          entries.each do |entry|
            type_display = renderer.colorize("[#{entry.entry_type}]", entry_type_color(entry.entry_type))
            println "  #{renderer.colorize(entry.name, :cyan)} #{type_display}"
            if entry.summary.present?
              summary = entry.summary.truncate(60)
              println "    #{renderer.colorize(summary, :gray)}"
            end
          end
        end

        println ""
      end

      def read_entry(slug_or_name)
        if slug_or_name.blank?
          println renderer.colorize("Usage: read <slug or name>", :amber)
          return
        end

        # Try to find by slug first, then by name
        slug = generate_slug(slug_or_name)
        entry = CodexEntry.published.find_by(slug: slug)
        entry ||= CodexEntry.published.where("LOWER(name) = ?", slug_or_name.downcase).first

        unless entry
          println renderer.colorize("Entry not found: #{slug_or_name}", :red)
          println renderer.colorize("Try 'search #{slug_or_name}' to find related entries.", :gray)
          return
        end

        display_entry(entry)
      end

      def display_entry(entry)
        type_color = entry_type_color(entry.entry_type)

        println ""
        println renderer.double_line(width: 60, color: type_color)
        println renderer.bold_color(entry.name.upcase, :cyan)
        println renderer.colorize("[#{entry.entry_type.titleize}]", type_color)
        println renderer.double_line(width: 60, color: type_color)

        if entry.summary.present?
          println ""
          println renderer.colorize(entry.summary, :white)
        end

        if entry.content.present?
          println ""
          println renderer.divider("CONTENT", width: 60, color: :gray)
          println ""

          # Convert markdown and wiki links to terminal-friendly format
          content = convert_content(entry.content)
          println content
        end

        # Show metadata if present
        if entry.metadata.present? && entry.metadata.any?
          println ""
          println renderer.divider("METADATA", width: 60, color: :gray)
          println ""
          entry.metadata.each do |key, value|
            println "  #{renderer.colorize(key.titleize + ":", :amber)} #{value}"
          end
        end

        println ""
        println renderer.double_line(width: 60, color: type_color)
        println ""
      end

      def show_recent
        entries = CodexEntry.published.order(updated_at: :desc).limit(10)

        println ""
        println renderer.divider("RECENTLY UPDATED", width: 60, color: :cyan)
        println ""

        entries.each do |entry|
          type_display = renderer.colorize("[#{entry.entry_type}]", entry_type_color(entry.entry_type))
          time_display = renderer.colorize(time_ago(entry.updated_at), :gray)
          println "  #{renderer.colorize(entry.name, :cyan)} #{type_display} - #{time_display}"
        end

        println ""
      end

      def convert_content(content)
        # Convert [[wiki links]] to highlighted text
        result = content.gsub(/\[\[([^\]|]+)(?:\|([^\]]+))?\]\]/) do
          entry_ref = $1
          display_text = $2 || entry_ref
          renderer.colorize("[#{display_text}]", :cyan)
        end

        # Convert markdown headers to colored text
        result.gsub!(/^###\s*(.+)$/) { renderer.colorize("  #{$1}", :amber) }
        result.gsub!(/^##\s*(.+)$/) { renderer.bold_color($1.to_s, :amber) }
        result.gsub!(/^#\s*(.+)$/) { renderer.bold_color($1.upcase, :cyan) }

        # Convert bold/italic
        result.gsub!(/\*\*(.+?)\*\*/) { renderer.bold($1) }
        result.gsub!(/\*(.+?)\*/) { renderer.colorize($1, :white) }

        # Convert bullet points
        result.gsub!(/^[-*]\s+/, "  \u2022 ")

        # Strip HTML tags that might be in content
        result.gsub!(/<[^>]+>/, "")

        result
      end

      def entry_type_color(type)
        case type
        when "person" then :purple
        when "organization" then :blue
        when "event" then :pink
        when "location" then :green
        when "technology" then :yellow
        when "faction" then :red
        when "item" then :lime
        else :white
        end
      end
    end
  end
end
