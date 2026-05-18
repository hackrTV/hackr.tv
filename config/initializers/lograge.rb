# frozen_string_literal: true

Rails.application.configure do
  config.lograge.enabled = !Rails.env.development?
  config.lograge.keep_original_rails_log = false
  config.lograge.formatter = Lograge::Formatters::Json.new

  # Silence health checks (already silenced in production.rb, belt-and-suspenders)
  config.lograge.ignore_actions = ["Rails::HealthController#show"]

  config.lograge.custom_options = lambda do |event|
    # Use Rails' built-in parameter filter to strip passwords, tokens, etc.
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    raw_params = event.payload[:params]&.except("controller", "action", "format")
    filtered = raw_params.present? ? filter.filter(raw_params) : nil

    {
      request_id: event.payload[:headers]&.fetch("action_dispatch.request_id", nil),
      params: filtered,
      hackr_id: event.payload[:hackr_id],
      hackr_alias: event.payload[:hackr_alias],
      slow: event.duration > ENV.fetch("SLOW_REQUEST_MS", "1000").to_f,
      exception: event.payload[:exception_object]&.then { |e| "#{e.class}: #{e.message}" }
    }.compact
  end
end
