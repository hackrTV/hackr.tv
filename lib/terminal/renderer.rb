# frozen_string_literal: true

require "cgi"

module Terminal
  # Renders content with ANSI colors and formatting for terminal output
  # Handles conversion from HTML (Grid::CommandParser output) to ANSI
  class Renderer
    include ANSI

    attr_reader :color_scheme

    def initialize(color_scheme: :default)
      @color_scheme = color_scheme
    end

    # Set the active color scheme
    # @param scheme [Symbol] Scheme name (:default, :amber, :green, :cga)
    def color_scheme=(scheme)
      @color_scheme = SCHEME_NAMES.include?(scheme) ? scheme : :default
    end

    # Get current color palette
    # @return [Hash] Current color scheme colors
    def colors
      COLOR_SCHEMES[@color_scheme] || COLOR_SCHEMES[:default]
    end

    # Convert HTML output from Grid::CommandParser to ANSI-formatted terminal text
    # @param html_content [String] HTML with inline style colors
    # @return [String] Text with ANSI escape codes
    def html_to_ansi(html_content)
      return "" if html_content.nil? || html_content.empty?

      result = html_content.dup

      # Convert rainbow unicorn spans to static per-character ANSI colors
      rainbow_colors = [
        "\e[38;2;255;107;107m",
        "\e[38;2;251;191;36m",
        "\e[38;2;52;211;153m",
        "\e[38;2;34;211;238m",
        "\e[38;2;96;165;250m",
        "\e[38;2;167;139;250m"
      ]
      result.gsub!(/<span\s+class='rarity-unicorn'>(.*?)<\/span>/im) do
        content = $1
        # Strip any nested HTML tags for clean character coloring
        plain = content.gsub(/<[^>]+>/, "")
        plain.chars.each_with_index.map { |char, i|
          "#{rainbow_colors[i % rainbow_colors.size]}#{char}#{RESET}"
        }.join
      end

      # Convert spans with style attributes to ANSI
      # Pattern handles: color, font-weight, and combinations
      result.gsub!(/<span\s+style='([^']*)'>(.*?)<\/span>/im) do
        style = $1
        content = $2

        ansi_codes = []

        # Extract color
        if style =~ /color:\s*(#[a-f0-9]{3,6})/i
          hex = $1.downcase
          # Normalize 3-digit hex to 6-digit
          hex = "##{hex[1] * 2}#{hex[2] * 2}#{hex[3] * 2}" if hex.length == 4
          ansi_codes << (HEX_TO_ANSI[hex] || COLORS[:white])
        end

        # Extract font-weight
        if /font-weight:\s*bold/i.match?(style)
          ansi_codes << BOLD
        end

        # Build ANSI string
        if ansi_codes.any?
          "#{ansi_codes.join}#{content}#{RESET}"
        else
          content
        end
      end

      # Handle div containers (just extract content)
      result.gsub!(/<div[^>]*>(.*?)<\/div>/im, '\1')

      # Handle line breaks
      result.gsub!(/<br\s*\/?>/, "\n")

      # Strip any remaining HTML tags
      result.gsub!(/<[^>]+>/, "")

      # Decode HTML entities
      CGI.unescapeHTML(result)
    end

    # Colorize text with a named color
    # @param text [String] Text to colorize
    # @param color [Symbol] Color name from current color scheme
    # @return [String] ANSI-colored text
    def colorize(text, color)
      color_code = colors[color] || colors[:white]
      "#{color_code}#{text}#{RESET}"
    end

    # Apply bold formatting
    # @param text [String] Text to make bold
    # @return [String] Bold ANSI text
    def bold(text)
      "#{BOLD}#{text}#{RESET}"
    end

    # Apply dim formatting
    # @param text [String] Text to dim
    # @return [String] Dimmed ANSI text
    def dim(text)
      "#{DIM}#{text}#{RESET}"
    end

    # Combine color and bold
    # @param text [String] Text to format
    # @param color [Symbol] Color name
    # @return [String] Bold colored ANSI text
    def bold_color(text, color)
      color_code = colors[color] || colors[:white]
      "#{BOLD}#{color_code}#{text}#{RESET}"
    end

    # Draw a horizontal line
    # @param width [Integer] Line width in characters
    # @param color [Symbol] Color for the line
    # @param char [String] Character to use for the line
    # @return [String] Colored horizontal line
    def line(width: 60, color: :purple, char: Box::HORIZONTAL)
      colorize(char * width, color)
    end

    # Draw a double horizontal line
    # @param width [Integer] Line width
    # @param color [Symbol] Color for the line
    # @return [String] Colored double line
    def double_line(width: 60, color: :purple)
      colorize(Box::DOUBLE_HORIZONTAL * width, color)
    end

    # Draw a box around content
    # @param content [String] Content to box
    # @param width [Integer] Box width
    # @param color [Symbol] Box border color
    # @param title [String, nil] Optional title for the box
    # @return [String] Boxed content
    def box(content, width: 60, color: :cyan, title: nil)
      lines = content.to_s.split("\n")
      inner_width = width - 4  # Account for borders and padding

      output = []

      # Top border with optional title
      if title
        title_display = " #{title} "
        title_len = visible_length(title_display)
        remaining = width - 2 - title_len
        left_pad = remaining / 2
        right_pad = remaining - left_pad
        top = "#{Box::DOUBLE_TOP_LEFT}#{Box::DOUBLE_HORIZONTAL * left_pad}#{title_display}#{Box::DOUBLE_HORIZONTAL * right_pad}#{Box::DOUBLE_TOP_RIGHT}"
      else
        top = "#{Box::DOUBLE_TOP_LEFT}#{Box::DOUBLE_HORIZONTAL * (width - 2)}#{Box::DOUBLE_TOP_RIGHT}"
      end
      output << colorize(top, color)

      # Content lines
      lines.each do |line_text|
        padded = pad_to_width(line_text, inner_width)
        output << "#{colorize(Box::DOUBLE_VERTICAL, color)} #{padded} #{colorize(Box::DOUBLE_VERTICAL, color)}"
      end

      # Bottom border
      bottom = "#{Box::DOUBLE_BOTTOM_LEFT}#{Box::DOUBLE_HORIZONTAL * (width - 2)}#{Box::DOUBLE_BOTTOM_RIGHT}"
      output << colorize(bottom, color)

      output.join("\n")
    end

    # Create a simple single-line box header
    # @param title [String] Title text
    # @param width [Integer] Total width
    # @param color [Symbol] Color for the header
    # @return [String] Formatted header
    def header(title, width: 60, color: :cyan)
      title_display = " #{title} "
      title_len = visible_length(title_display)
      remaining = width - title_len
      left_pad = remaining / 2
      right_pad = remaining - left_pad

      colorize("#{Box::DOUBLE_HORIZONTAL * left_pad}#{title_display}#{Box::DOUBLE_HORIZONTAL * right_pad}", color)
    end

    # Create a section divider with centered text
    # @param text [String] Divider text
    # @param width [Integer] Total width
    # @param color [Symbol] Color
    # @return [String] Formatted divider
    def divider(text = nil, width: 60, color: :gray)
      if text
        text_display = " #{text} "
        text_len = visible_length(text_display)
        remaining = width - text_len
        left_pad = remaining / 2
        right_pad = remaining - left_pad
        colorize("#{Box::HORIZONTAL * left_pad}#{text_display}#{Box::HORIZONTAL * right_pad}", color)
      else
        colorize(Box::HORIZONTAL * width, color)
      end
    end

    # Format a key-value pair
    # @param key [String] Label
    # @param value [String] Value
    # @param key_color [Symbol] Color for key
    # @param value_color [Symbol] Color for value
    # @return [String] Formatted key-value pair
    def key_value(key, value, key_color: :amber, value_color: :white)
      "#{colorize(key, key_color)} #{colorize(value, value_color)}"
    end

    # Format a menu item
    # @param key [String] Menu key (e.g., "1", "L")
    # @param label [String] Menu item label
    # @param disabled [Boolean] Whether item is disabled
    # @param note [String, nil] Optional note (e.g., "[LOGIN REQUIRED]")
    # @return [String] Formatted menu item
    def menu_item(key, label, disabled: false, note: nil)
      key_display = colorize("[#{key}]", disabled ? :gray : :cyan)
      label_display = colorize(label, disabled ? :gray : :white)
      note_display = note ? " #{colorize(note, :red)}" : ""

      "  #{key_display} #{label_display}#{note_display}"
    end

    # Clear the terminal screen
    # @return [String] ANSI clear screen sequence
    def clear_screen
      CLEAR_SCREEN
    end

    # Format a timestamp relative to now
    # @param time [Time] The time to format
    # @return [String] Relative time string (e.g., "2h ago")
    def time_ago(time)
      return "just now" unless time

      seconds = (Time.current - time).to_i
      case seconds
      when 0..59 then "just now"
      when 60..3599 then "#{seconds / 60}m ago"
      when 3600..86399 then "#{seconds / 3600}h ago"
      else "#{seconds / 86400}d ago"
      end
    end

    private

    # Calculate visible string length (ignoring ANSI codes)
    # @param str [String] String possibly containing ANSI codes
    # @return [Integer] Visible character count
    def visible_length(str)
      str.gsub(/\e\[[0-9;]*m/, "").length
    end

    # Pad string to specified width (accounting for ANSI codes)
    # @param str [String] String to pad
    # @param width [Integer] Target width
    # @return [String] Padded string
    def pad_to_width(str, width)
      visible = visible_length(str)
      padding = width - visible
      (padding > 0) ? str + (" " * padding) : str
    end
  end
end
