# Rate limiting configuration using Rack::Attack
# Protects against brute force attacks and abuse

class Rack::Attack
  # Parse JSON body for POST requests since Rack::Request#params
  # doesn't include JSON body fields at middleware time
  def self.json_params(req)
    return req.env["rack_attack.json_params"] if req.env.key?("rack_attack.json_params")

    parsed = if req.post? && req.content_type&.include?("application/json")
      begin
        body = req.body.read
        req.body.rewind
        JSON.parse(body)
      rescue JSON::ParserError
        {}
      end
    else
      {}
    end

    req.env["rack_attack.json_params"] = parsed
  end

  # Safely extract a string value from parsed JSON params.
  # Returns nil for non-string values (arrays, hashes, numbers)
  # to avoid NoMethodError/TypeError in throttle key blocks.
  def self.json_string_param(req, key)
    value = json_params(req)[key]
    value.is_a?(String) ? value.downcase.strip : nil
  end

  ### Throttle login attempts ###

  # Throttle login attempts by IP address
  # 5 requests per 20 seconds
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    if req.path == "/api/grid/login" && req.post?
      req.ip
    end
  end

  # Throttle login attempts by hackr_alias parameter
  # 5 requests per 20 seconds per alias
  throttle("logins/alias", limit: 5, period: 20.seconds) do |req|
    if req.path == "/api/grid/login" && req.post?
      json_string_param(req, "hackr_alias")
    end
  end

  ### Throttle registration attempts ###

  # Prevent registration email spam
  # 3 registration emails per IP per hour
  throttle("registrations/ip", limit: 3, period: 1.hour) do |req|
    if req.path == "/api/grid/register" && req.post?
      req.ip
    end
  end

  # 3 registration emails per email address per hour
  throttle("registrations/email", limit: 3, period: 1.hour) do |req|
    if req.path == "/api/grid/register" && req.post?
      json_string_param(req, "email")
    end
  end

  ### Throttle forgot password attempts ###

  # 3 forgot password requests per IP per hour
  throttle("forgot_password/ip", limit: 3, period: 1.hour) do |req|
    if req.path == "/api/grid/forgot_password" && req.post?
      req.ip
    end
  end

  # 3 forgot password requests per email per hour
  throttle("forgot_password/email", limit: 3, period: 1.hour) do |req|
    if req.path == "/api/grid/forgot_password" && req.post?
      json_string_param(req, "email")
    end
  end

  ### Throttle TOTP verification ###

  # 5 TOTP verify attempts per 2 minutes per IP (brute-force protection)
  throttle("totp_verify/ip", limit: 5, period: 2.minutes) do |req|
    if req.path == "/api/totp/verify" && req.post?
      req.ip
    end
  end

  # 5 TOTP setup/enable/disable attempts per 15 minutes per IP
  throttle("totp_manage/ip", limit: 5, period: 15.minutes) do |req|
    if (%w[/api/totp/setup /api/totp/enable].include?(req.path) && req.post?) ||
        (req.path == "/api/totp/disable" && req.delete?)
      req.ip
    end
  end

  ### Throttle token verification ###

  # 10 token verifications per IP per minute
  throttle("verify_token/ip", limit: 10, period: 1.minute) do |req|
    if req.path.start_with?("/api/grid/verify/") && req.get?
      req.ip
    end
  end

  ### Throttle registration completion ###

  # 5 completion attempts per token per hour
  throttle("complete_registration/token", limit: 5, period: 1.hour) do |req|
    if req.path == "/api/grid/complete_registration" && req.post?
      json_string_param(req, "token")
    end
  end

  ### Throttle API requests ###

  # General API throttle - 300 requests per minute per IP
  # The tactical UI fires 3-5 parallel fetches per command action
  # (zone_map, transit, loadout, shop, etc.), so 100/min is too tight.
  throttle("api/ip", limit: 300, period: 1.minute) do |req|
    if req.path.start_with?("/api/")
      req.ip
    end
  end

  ### Custom response for throttled requests ###

  self.throttled_responder = lambda do |request|
    match_data = request.env["rack.attack.match_data"]
    now = match_data[:epoch_time]
    retry_after = match_data[:period] - (now % match_data[:period])

    [
      429,
      {
        "Content-Type" => "application/json",
        "Retry-After" => retry_after.to_s
      },
      [{
        error: "Rate limit exceeded. Try again in #{retry_after} seconds.",
        retry_after: retry_after
      }.to_json]
    ]
  end

  ### Blocklist repeated offenders ###

  # Block IPs that have been throttled 5+ times in 1 hour
  blocklist("repeated_offenders") do |req|
    # After 5 blocked requests in 1 hour, block for 1 hour
    Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 5, findtime: 1.hour, bantime: 1.hour) do
      # Track all throttled requests
      req.env["rack.attack.matched"]
    end
  end
end

# Enable Rack::Attack in all environments
Rails.application.config.middleware.use Rack::Attack
