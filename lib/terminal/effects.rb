# frozen_string_literal: true

module Terminal
  # Visual effects for terminal output
  # Provides glitch, typing, scanline, and other cyberpunk effects
  class Effects
    include ANSI

    # Characters used for glitch effect
    GLITCH_CHARS = %w[█ ▓ ▒ ░ ╳ ╱ ╲ │ ─ ┼ ¦ ǁ ≡ ∞ Ø ◊ ◦ • ■ □].freeze

    # Characters for data corruption effect
    CORRUPT_CHARS = %w[0 1 $ # @ ! ? % & * ~ ^ ` | \\ /].freeze

    # Characters for matrix rain
    MATRIX_CHARS = ("ァ".."ン").to_a + ("0".."9").to_a

    class << self
      # Apply glitch effect to text - randomly replace characters
      # @param text [String] Text to glitch
      # @param intensity [Float] Probability of replacing each char (0.0-1.0)
      # @return [String] Glitched text
      def glitch_text(text, intensity: 0.1)
        text.chars.map do |char|
          if char =~ /\S/ && rand < intensity
            GLITCH_CHARS.sample
          else
            char
          end
        end.join
      end

      # Apply data corruption effect - replace with binary/symbols
      # @param text [String] Text to corrupt
      # @param intensity [Float] Corruption probability (0.0-1.0)
      # @return [String] Corrupted text
      def corrupt_text(text, intensity: 0.15)
        text.chars.map do |char|
          if char =~ /\S/ && rand < intensity
            CORRUPT_CHARS.sample
          else
            char
          end
        end.join
      end

      # Output text with typing effect (character by character)
      # @param io [IO] Output stream
      # @param text [String] Text to type
      # @param delay [Float] Delay between characters in seconds
      # @param variation [Float] Random variation in delay
      def typing_effect(io, text, delay: 0.02, variation: 0.01)
        text.each_char do |char|
          io.print char
          io.flush
          actual_delay = delay + rand(-variation..variation)
          sleep(actual_delay) unless char == "\n"
        end
      end

      # Output text with scanline effect (line by line)
      # @param io [IO] Output stream
      # @param text [String] Text to display
      # @param delay [Float] Delay between lines in seconds
      def scanline_effect(io, text, delay: 0.03)
        text.each_line do |line|
          io.print line
          io.flush
          sleep(delay)
        end
      end

      # Flicker a banner with glitch frames
      # @param io [IO] Output stream
      # @param banner [String] Banner text to flicker
      # @param flickers [Integer] Number of flicker cycles
      # @param glitch_intensity [Float] How glitchy the flickers are
      def flicker_banner(io, banner, flickers: 3, glitch_intensity: 0.3)
        flickers.times do
          # Show glitched version briefly
          io.print CLEAR_SCREEN
          io.print glitch_text(banner, intensity: glitch_intensity)
          io.flush
          sleep(0.05 + rand(0.05))

          # Show clean version
          io.print CLEAR_SCREEN
          io.print banner
          io.flush
          sleep(0.08 + rand(0.05))
        end
      end

      # Display text with a "decrypting" reveal effect
      # @param io [IO] Output stream
      # @param text [String] Final text to reveal
      # @param iterations [Integer] Number of decrypt iterations
      # @param delay [Float] Delay between iterations
      def decrypt_effect(io, text, iterations: 5, delay: 0.08)
        visible_chars = Array.new(text.length, false)
        chars_per_iteration = (text.length / iterations.to_f).ceil

        iterations.times do |i|
          # Reveal more characters each iteration
          chars_to_reveal = [chars_per_iteration, text.length - visible_chars.count(true)].min
          unrevealed = visible_chars.each_index.select { |idx| !visible_chars[idx] && text[idx] =~ /\S/ }
          unrevealed.sample(chars_to_reveal).each { |idx| visible_chars[idx] = true }

          # Build display string
          display = text.chars.each_with_index.map do |char, idx|
            if visible_chars[idx] || char =~ /\s/
              char
            else
              CORRUPT_CHARS.sample
            end
          end.join

          io.print "\r#{display}"
          io.flush
          sleep(delay)
        end

        # Final clean reveal
        io.print "\r#{text}"
        io.puts
      end

      # Create a loading bar animation
      # @param io [IO] Output stream
      # @param width [Integer] Bar width in characters
      # @param duration [Float] Total animation duration in seconds
      # @param label [String] Optional label before the bar
      def loading_bar(io, width: 30, duration: 1.5, label: "LOADING")
        steps = width
        delay = duration / steps

        steps.times do |i|
          filled = "█" * (i + 1)
          empty = "░" * (width - i - 1)
          percent = ((i + 1) * 100 / steps)
          io.print "\r#{label} [#{filled}#{empty}] #{percent}%"
          io.flush
          sleep(delay)
        end
        io.puts
      end

      # Display a "hacking" progress animation
      # @param io [IO] Output stream
      # @param message [String] Message to display
      # @param duration [Float] Animation duration
      def hacking_animation(io, message: "ACCESSING SYSTEM", duration: 2.0)
        frames = ["◐", "◓", "◑", "◒"]
        iterations = (duration / 0.1).to_i

        iterations.times do |i|
          frame = frames[i % frames.length]
          dots = "." * ((i % 4) + 1)
          io.print "\r#{frame} #{message}#{dots.ljust(4)}"
          io.flush
          sleep(0.1)
        end
        io.puts "\r✓ #{message}    "
      end

      # Apply color gradient to text (left to right)
      # @param text [String] Text to colorize
      # @param start_color [Symbol] Starting color
      # @param end_color [Symbol] Ending color
      # @return [String] Gradient-colored text
      def gradient_text(text, start_color: :cyan, end_color: :purple)
        return text if text.empty?

        start_rgb = color_to_rgb(start_color)
        end_rgb = color_to_rgb(end_color)
        length = text.gsub(/\s/, "").length
        return text if length.zero?

        char_index = 0
        text.chars.map do |char|
          if char.match?(/\s/)
            char
          else
            ratio = char_index.to_f / [length - 1, 1].max
            r = interpolate(start_rgb[0], end_rgb[0], ratio)
            g = interpolate(start_rgb[1], end_rgb[1], ratio)
            b = interpolate(start_rgb[2], end_rgb[2], ratio)
            char_index += 1
            "\e[38;2;#{r};#{g};#{b}m#{char}#{RESET}"
          end
        end.join
      end

      # Create a box around text with optional title
      # @param text [String] Content to box
      # @param title [String, nil] Optional title
      # @param color [Symbol] Box color
      # @param width [Integer] Box width (auto if nil)
      # @return [String] Boxed text
      def boxed(text, title: nil, color: :cyan, width: nil)
        lines = text.split("\n")
        max_line = lines.map { |l| visible_length(l) }.max || 0
        box_width = width || [max_line + 4, 40].max

        color_code = COLORS[color] || COLORS[:white]
        result = []

        # Top border
        if title
          title_display = " #{title} "
          remaining = box_width - 2 - title_display.length
          left = remaining / 2
          right = remaining - left
          result << "#{color_code}╔#{"═" * left}#{title_display}#{"═" * right}╗#{RESET}"
        else
          result << "#{color_code}╔#{"═" * (box_width - 2)}╗#{RESET}"
        end

        # Content
        lines.each do |line|
          padding = box_width - 4 - visible_length(line)
          result << "#{color_code}║#{RESET} #{line}#{" " * [padding, 0].max} #{color_code}║#{RESET}"
        end

        # Bottom border
        result << "#{color_code}╚#{"═" * (box_width - 2)}╝#{RESET}"

        result.join("\n")
      end

      private

      def visible_length(str)
        str.gsub(/\e\[[0-9;]*m/, "").length
      end

      def color_to_rgb(color)
        case color
        when :cyan then [34, 211, 238]
        when :purple then [167, 139, 250]
        when :amber then [251, 191, 36]
        when :green then [52, 211, 153]
        when :red then [248, 113, 113]
        when :blue then [96, 165, 250]
        when :pink then [244, 114, 182]
        else [229, 231, 235] # white
        end
      end

      def interpolate(start_val, end_val, ratio)
        (start_val + (end_val - start_val) * ratio).round
      end
    end
  end
end
