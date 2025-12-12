# Rate limiting configuration using Rack::Attack
# Protects against brute force attacks and abuse

class Rack::Attack
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
      # Normalize alias to prevent bypass via case variations
      req.params["hackr_alias"]&.downcase&.strip
    end
  end

  ### Throttle registration attempts ###

  # Prevent registration spam
  # 3 registrations per IP per hour
  throttle("registrations/ip", limit: 3, period: 1.hour) do |req|
    if req.path == "/api/grid/register" && req.post?
      req.ip
    end
  end

  ### Throttle API requests ###

  # General API throttle - 100 requests per minute per IP
  throttle("api/ip", limit: 100, period: 1.minute) do |req|
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

  # Block IPs that have been throttled 10+ times in 10 minutes
  blocklist("repeated_offenders") do |req|
    # After 10 blocked requests in 10 minutes, block for 1 hour
    Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 10, findtime: 10.minutes, bantime: 1.hour) do
      # Track all throttled requests
      req.env["rack.attack.matched"]
    end
  end
end

# Enable Rack::Attack in all environments
Rails.application.config.middleware.use Rack::Attack
