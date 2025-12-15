# frozen_string_literal: true

require "digest"

module Terminal
  # Generates and validates daily rotating passwords for SSH terminal access
  # Password rotation creates an in-world ritual where users must visit
  # hackr.tv/terminal to get current access credentials
  class Password
    # Cyberpunk-themed word list for password generation
    WORD_LIST = %w[
      fracture pulse grid cipher neon ghost signal
      hack surge breach shadow node vector zero
      volt drift apex echo wire chrome static
      prism neural glitch sync flux core trace
      phantom vertex proxy daemon socket packet
      protocol binary quantum kernel buffer stack
      override decrypt encrypt tunnel firewall
      matrix nexus vortex specter codec stream
    ].freeze

    # Seed phrase for deterministic generation (reference to 9/9/2115 - Fracture Day)
    SEED = "fracture-day-9915"

    class << self
      # Generate today's password
      # Format: word-word-word (e.g., "neon-cipher-ghost")
      # @return [String] Today's rotating password
      def daily_password
        generate_password_for_date(Date.current)
      end

      # Generate password for a specific date (useful for testing)
      # @param date [Date] The date to generate password for
      # @return [String] Password for that date
      def generate_password_for_date(date)
        date_seed = "#{date}#{SEED}"
        # Use SHA256 for deterministic random generation
        hash = Digest::SHA256.hexdigest(date_seed)
        rng = Random.new(hash.to_i(16))

        # Generate 3-word passphrase
        3.times.map { WORD_LIST[rng.rand(WORD_LIST.size)] }.join("-")
      end

      # Check if a password is valid for today
      # @param password [String] Password to validate
      # @return [Boolean] True if password matches today's password
      def valid?(password)
        return false if password.nil? || password.empty?
        password.downcase.strip == daily_password
      end

      # Get time until next password rotation (midnight UTC)
      # @return [ActiveSupport::Duration] Time remaining
      def time_until_rotation
        next_midnight = Date.tomorrow.beginning_of_day
        next_midnight - Time.current
      end

      # Format time until rotation as HH:MM:SS
      # @return [String] Formatted countdown
      def rotation_countdown
        remaining = time_until_rotation.to_i
        hours = remaining / 3600
        minutes = (remaining % 3600) / 60
        seconds = remaining % 60
        format("%02d:%02d:%02d", hours, minutes, seconds)
      end

      # Get the next rotation time
      # @return [Time] Time of next password rotation
      def next_rotation_at
        Date.tomorrow.beginning_of_day
      end
    end
  end
end
