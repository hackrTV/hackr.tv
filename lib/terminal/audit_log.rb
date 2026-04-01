# frozen_string_literal: true

module Terminal
  # Buffered audit logger for terminal sessions.
  # Accumulates events in memory and bulk-inserts to minimize writes.
  # Every public method rescues exceptions — logging must never crash a session.
  class AuditLog
    BUFFER_SIZE = 10
    MAX_INPUT_LENGTH = 500

    attr_reader :session_record

    def initialize(ip_address: nil)
      @ip_address = ip_address
      @session_record = nil
      @buffer = []
    end

    def start_session
      @session_record = TerminalSession.create!(
        ip_address: @ip_address,
        connected_at: Time.current
      )
      track(:session_start)
    rescue => e
      Rails.logger.error "[AuditLog] start_session failed: #{e.message}"
    end

    def end_session(reason: "normal")
      flush
      track(:session_end, metadata: { reason: reason })
      flush
      @session_record&.close!(reason: reason)
    rescue => e
      Rails.logger.error "[AuditLog] end_session failed: #{e.message}"
    end

    def associate_hackr(hackr)
      return unless @session_record

      @session_record.update!(grid_hackr_id: hackr.id)
    rescue => e
      Rails.logger.error "[AuditLog] associate_hackr failed: #{e.message}"
    end

    def track(event_type, handler: nil, input: nil, metadata: nil)
      return unless @session_record

      @buffer << {
        terminal_session_id: @session_record.id,
        event_type: event_type.to_s,
        handler: handler&.to_s,
        input: input&.to_s&.truncate(MAX_INPUT_LENGTH),
        metadata: metadata&.to_json,
        created_at: Time.current
      }

      flush if @buffer.size >= BUFFER_SIZE
    rescue => e
      Rails.logger.error "[AuditLog] track failed: #{e.message}"
    end

    def flush
      return if @buffer.empty?

      TerminalEvent.insert_all(@buffer)
      @buffer.clear
    rescue => e
      Rails.logger.error "[AuditLog] flush failed: #{e.message}"
      @buffer.clear
    end
  end
end
