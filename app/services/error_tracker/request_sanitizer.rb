# frozen_string_literal: true

module ErrorTracker
  # Extracts and sanitizes request context from a Rack env hash.
  # Strips sensitive parameters matching common credential patterns.
  module RequestSanitizer
    SENSITIVE_PATTERN = /password|token|secret|auth|key|cvv|ssn|otp/i
    MAX_PARAMS_SIZE = 4096

    module_function

    def from_env(env)
      request = ActionDispatch::Request.new(env)
      params = sanitize_params(request.filtered_parameters.except("controller", "action", "format"))

      {
        request_url: request.original_url.to_s.truncate(2048),
        request_method: request.method,
        request_params: truncate_json(params),
        ip_address: request.remote_ip,
        user_agent: request.user_agent&.truncate(500)
      }
    end

    def sanitize_params(params)
      case params
      when Hash
        params.each_with_object({}) do |(key, value), result|
          result[key] = if key.to_s.match?(SENSITIVE_PATTERN)
            "[FILTERED]"
          else
            sanitize_params(value)
          end
        end
      when Array
        params.map { |v| sanitize_params(v) }
      else
        params
      end
    end

    def truncate_json(params)
      json = params.to_json
      (json.size > MAX_PARAMS_SIZE) ? json.truncate(MAX_PARAMS_SIZE) : json
    end
  end
end
