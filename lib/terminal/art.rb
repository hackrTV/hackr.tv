# frozen_string_literal: true

module Terminal
  # Loads and caches ASCII art assets for terminal display
  # Art files are stored in lib/terminal/art/ as plain text files
  class Art
    ART_PATH = File.expand_path("art", __dir__)

    class << self
      # Load a banner by name
      # @param name [String, Symbol] Banner name (without .txt extension)
      # @return [String] Banner content or empty string if not found
      def banner(name)
        load_art("banners/#{name}")
      end

      # Load a frame/border element by name
      # @param name [String, Symbol] Frame name (without .txt extension)
      # @return [String] Frame content or empty string if not found
      def frame(name)
        load_art("frames/#{name}")
      end

      # Load all frames for an animation
      # @param name [String, Symbol] Animation directory name
      # @return [Array<String>] Array of frame contents in order
      def animation_frames(name)
        dir = File.join(ART_PATH, "animations", name.to_s)
        return [] unless File.directory?(dir)

        Dir[File.join(dir, "*.txt")].sort.map { |f| File.read(f) }
      end

      # Check if a banner exists
      # @param name [String, Symbol] Banner name
      # @return [Boolean]
      def banner_exists?(name)
        File.exist?(File.join(ART_PATH, "banners", "#{name}.txt"))
      end

      # List all available banners
      # @return [Array<String>] Banner names without extensions
      def available_banners
        Dir[File.join(ART_PATH, "banners", "*.txt")].map do |f|
          File.basename(f, ".txt")
        end.sort
      end

      # Clear the art cache (useful for development)
      def clear_cache
        @cache&.clear
      end

      private

      def load_art(path)
        @cache ||= {}
        cache_key = path.to_s

        return @cache[cache_key] if @cache.key?(cache_key)

        file_path = File.join(ART_PATH, "#{path}.txt")

        @cache[cache_key] = if File.exist?(file_path)
          File.read(file_path)
        else
          ""
        end
      end
    end
  end
end
