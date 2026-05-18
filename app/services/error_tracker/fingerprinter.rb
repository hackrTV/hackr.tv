# frozen_string_literal: true

require "digest"

module ErrorTracker
  # Generates deterministic fingerprints for error grouping.
  # Backend: SHA256 of exception class + normalized backtrace.
  # Frontend: SHA256 of message (numbers normalized) + source file + line number.
  module Fingerprinter
    module_function

    def backend(exception)
      trace = normalize_backtrace(exception.backtrace || [])
      Digest::SHA256.hexdigest("#{exception.class.name}:#{trace}")
    end

    def frontend(message:, source:, lineno:)
      normalized_message = message.to_s.gsub(/\b\d+\b/, "N")
      Digest::SHA256.hexdigest("frontend:#{normalized_message}:#{source}:#{lineno}")
    end

    # Strip line numbers from backtrace frames but keep method names.
    # "/app/services/grid/breach_service.rb:42:in `start!'" → "/app/services/grid/breach_service.rb:in `start!'"
    def normalize_backtrace(backtrace)
      backtrace
        .first(10)
        .map { |line| line.sub(/:\d+/, "") }
        .join("|")
    end
  end
end
