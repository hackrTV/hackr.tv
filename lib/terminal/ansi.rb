# frozen_string_literal: true

module Terminal
  # ANSI escape codes for terminal styling
  # Colors are 24-bit (truecolor) to match Grid::CommandParser HTML output
  module ANSI
    # Reset all formatting
    RESET = "\e[0m"

    # Color schemes for different terminal aesthetics
    # Each scheme maps semantic colors to actual ANSI codes
    COLOR_SCHEMES = {
      default: {
        amber: "\e[38;2;251;191;36m",
        cyan: "\e[38;2;34;211;238m",
        purple: "\e[38;2;167;139;250m",
        green: "\e[38;2;52;211;153m",
        red: "\e[38;2;248;113;113m",
        gray: "\e[38;2;156;163;175m",
        blue: "\e[38;2;96;165;250m",
        white: "\e[38;2;229;231;235m",
        black: "\e[38;2;17;24;39m",
        pink: "\e[38;2;244;114;182m",
        lime: "\e[38;2;163;230;53m",
        yellow: "\e[38;2;250;204;21m",
        mob_purple: "\e[38;2;192;132;252m"
      },
      amber: {
        # Classic amber phosphor CRT (all amber shades)
        amber: "\e[38;2;255;191;0m",      # Bright amber
        cyan: "\e[38;2;255;176;0m",        # Medium amber
        purple: "\e[38;2;204;153;0m",      # Darker amber
        green: "\e[38;2;255;200;50m",      # Light amber
        red: "\e[38;2;255;140;0m",         # Orange-amber
        gray: "\e[38;2;153;115;0m",        # Dim amber
        blue: "\e[38;2;230;172;0m",        # Mid amber
        white: "\e[38;2;255;210;100m",     # Bright amber
        black: "\e[38;2;51;38;0m",         # Very dark amber
        pink: "\e[38;2;255;165;0m",        # Orange amber
        lime: "\e[38;2;255;195;50m",       # Yellow amber
        yellow: "\e[38;2;255;200;50m",     # Yellow amber
        mob_purple: "\e[38;2;204;153;0m"   # Darker amber
      },
      green: {
        # Classic green phosphor CRT (all green shades)
        amber: "\e[38;2;50;255;50m",       # Bright green
        cyan: "\e[38;2;0;200;0m",          # Medium green
        purple: "\e[38;2;0;150;0m",        # Darker green
        green: "\e[38;2;50;255;100m",      # Light green
        red: "\e[38;2;100;200;0m",         # Yellow-green
        gray: "\e[38;2;0;100;0m",          # Dim green
        blue: "\e[38;2;0;180;0m",          # Mid green
        white: "\e[38;2;100;255;150m",     # Bright green
        black: "\e[38;2;0;30;0m",          # Very dark green
        pink: "\e[38;2;80;220;80m",        # Medium green
        lime: "\e[38;2;150;255;100m",      # Lime green
        yellow: "\e[38;2;100;255;100m",    # Bright green
        mob_purple: "\e[38;2;0;150;0m"     # Darker green
      },
      cga: {
        # CGA 4-color palette (cyan, magenta, white, black)
        amber: "\e[38;2;255;255;85m",      # CGA Yellow
        cyan: "\e[38;2;85;255;255m",       # CGA Cyan
        purple: "\e[38;2;255;85;255m",     # CGA Magenta
        green: "\e[38;2;85;255;85m",       # CGA Green
        red: "\e[38;2;255;85;85m",         # CGA Red
        gray: "\e[38;2;170;170;170m",      # CGA Gray
        blue: "\e[38;2;85;85;255m",        # CGA Blue
        white: "\e[38;2;255;255;255m",     # CGA White
        black: "\e[38;2;0;0;0m",           # CGA Black
        pink: "\e[38;2;255;85;255m",       # CGA Magenta
        lime: "\e[38;2;85;255;85m",        # CGA Green
        yellow: "\e[38;2;255;255;85m",     # CGA Yellow
        mob_purple: "\e[38;2;255;85;255m"  # CGA Magenta
      }
    }.freeze

    # Available scheme names
    SCHEME_NAMES = COLOR_SCHEMES.keys.freeze

    # Style modifiers
    BOLD = "\e[1m"
    DIM = "\e[2m"
    ITALIC = "\e[3m"
    UNDERLINE = "\e[4m"
    BLINK = "\e[5m"
    REVERSE = "\e[7m"

    # Cursor control
    HIDE_CURSOR = "\e[?25l"
    SHOW_CURSOR = "\e[?25h"
    SAVE_CURSOR = "\e[s"
    RESTORE_CURSOR = "\e[u"

    # Screen control
    CLEAR_SCREEN = "\e[2J\e[H"
    CLEAR_LINE = "\e[2K"
    CLEAR_TO_END = "\e[K"

    # 24-bit color definitions matching Grid::CommandParser HTML colors
    # Format: \e[38;2;R;G;Bm for foreground
    COLORS = {
      # Primary palette (from CommandParser)
      amber: "\e[38;2;251;191;36m",    # #fbbf24 - primary terminal color
      cyan: "\e[38;2;34;211;238m",     # #22d3ee - links, highlights
      purple: "\e[38;2;167;139;250m",  # #a78bfa - NPCs, special
      green: "\e[38;2;52;211;153m",    # #34d399 - success, items
      red: "\e[38;2;248;113;113m",     # #f87171 - errors, danger
      gray: "\e[38;2;156;163;175m",    # #9ca3af - muted, timestamps
      blue: "\e[38;2;96;165;250m",     # #60a5fa - info

      # Additional colors
      white: "\e[38;2;229;231;235m",   # #e5e7eb
      black: "\e[38;2;17;24;39m",      # #111827
      pink: "\e[38;2;244;114;182m",    # #f472b6 - events
      lime: "\e[38;2;163;230;53m",     # #a3e635 - items
      yellow: "\e[38;2;250;204;21m",   # #facc15

      # Mob/NPC colors from CommandParser
      mob_purple: "\e[38;2;192;132;252m" # #c084fc
    }.freeze

    # Background color versions
    BG_COLORS = {
      amber: "\e[48;2;251;191;36m",
      cyan: "\e[48;2;34;211;238m",
      purple: "\e[48;2;167;139;250m",
      green: "\e[48;2;52;211;153m",
      red: "\e[48;2;248;113;113m",
      gray: "\e[48;2;156;163;175m",
      blue: "\e[48;2;96;165;250m",
      black: "\e[48;2;17;24;39m"
    }.freeze

    # HTML hex to ANSI color mapping (for HTML-to-ANSI conversion)
    HEX_TO_ANSI = {
      "#fbbf24" => COLORS[:amber],
      "#22d3ee" => COLORS[:cyan],
      "#a78bfa" => COLORS[:purple],
      "#34d399" => COLORS[:green],
      "#f87171" => COLORS[:red],
      "#9ca3af" => COLORS[:gray],
      "#60a5fa" => COLORS[:blue],
      "#e5e7eb" => COLORS[:white],
      "#c084fc" => COLORS[:mob_purple],
      "#f472b6" => COLORS[:pink],
      "#a3e635" => COLORS[:lime],
      "#facc15" => COLORS[:yellow],
      "#ef4444" => COLORS[:red],
      "#6b7280" => COLORS[:gray],
      "#666" => COLORS[:gray],
      "#666666" => COLORS[:gray]
    }.freeze

    # Box drawing characters
    module Box
      HORIZONTAL = "\u2500"       # ─
      VERTICAL = "\u2502"         # │
      TOP_LEFT = "\u250C"         # ┌
      TOP_RIGHT = "\u2510"        # ┐
      BOTTOM_LEFT = "\u2514"      # └
      BOTTOM_RIGHT = "\u2518"     # ┘
      T_DOWN = "\u252C"           # ┬
      T_UP = "\u2534"             # ┴
      T_RIGHT = "\u251C"          # ├
      T_LEFT = "\u2524"           # ┤
      CROSS = "\u253C"            # ┼

      # Double line variants
      DOUBLE_HORIZONTAL = "\u2550" # ═
      DOUBLE_VERTICAL = "\u2551"   # ║
      DOUBLE_TOP_LEFT = "\u2554"   # ╔
      DOUBLE_TOP_RIGHT = "\u2557"  # ╗
      DOUBLE_BOTTOM_LEFT = "\u255A" # ╚
      DOUBLE_BOTTOM_RIGHT = "\u255D" # ╝
    end

    # Block characters for ASCII art
    module Blocks
      FULL = "\u2588"        # █
      DARK = "\u2593"        # ▓
      MEDIUM = "\u2592"      # ▒
      LIGHT = "\u2591"       # ░
      UPPER_HALF = "\u2580"  # ▀
      LOWER_HALF = "\u2584"  # ▄
    end
  end
end
