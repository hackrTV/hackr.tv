# frozen_string_literal: true

# Public API for error tracking. All methods are safe to call from anywhere —
# they never raise, never add latency to the request cycle beyond a single
# SQLite insert (~1ms).
#
#   ErrorTracker.track(exception, context: { hackr_id: 42 })
#   ErrorTracker.track_frontend(payload:, request:, hackr:)
#
module ErrorTracker
  module_function

  # Track a backend exception. Called from middleware (unhandled) or rescue blocks (manual).
  def track(exception, context: {})
    fingerprint = Fingerprinter.backend(exception)

    Persister.record(
      fingerprint: fingerprint,
      title: exception.class.name,
      component: "backend",
      severity: "error",
      occurred_at: Time.current,
      exception_class: exception.class.name,
      message: exception.message.to_s.truncate(1000),
      backtrace: exception.backtrace&.first(30)&.to_json,
      rails_env: Rails.env,
      hackr_id: context[:hackr_id],
      hackr_alias: context[:hackr_alias],
      request_url: context[:request_url],
      request_method: context[:request_method],
      request_params: context[:request_params],
      ip_address: context[:ip_address],
      user_agent: context[:user_agent],
      metadata: context[:metadata]&.to_json
    )
  rescue => e
    Rails.logger.error "[ErrorTracker] track failed: #{e.message}"
  end

  # Track a frontend error reported via API.
  def track_frontend(payload:, request:, hackr:)
    message = payload[:message].to_s.truncate(1000)
    source = payload[:source].to_s
    lineno = payload[:lineno].to_i
    fingerprint = Fingerprinter.frontend(message: message, source: source, lineno: lineno)

    Persister.record(
      fingerprint: fingerprint,
      title: message.truncate(200),
      component: "frontend",
      severity: "error",
      occurred_at: Time.current,
      exception_class: nil,
      message: message,
      backtrace: payload[:stack].present? ? payload[:stack].to_s.lines.first(20).to_json : nil,
      rails_env: Rails.env,
      hackr_id: hackr&.id,
      hackr_alias: hackr&.hackr_alias,
      request_url: payload[:url].to_s.truncate(2048),
      request_method: nil,
      request_params: nil,
      ip_address: request.remote_ip,
      user_agent: request.user_agent&.truncate(500),
      metadata: {
        type: payload[:type],
        source: source,
        lineno: lineno,
        colno: payload[:colno].to_i
      }.to_json
    )
  rescue => e
    Rails.logger.error "[ErrorTracker] track_frontend failed: #{e.message}"
  end
end
