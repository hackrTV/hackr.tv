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

  # Extract a param from either a JSON body (API) or a form-encoded body
  # (Hotwire pages) — the auth throttles cover both stacks with shared
  # counters, so an attacker alternating between them gets one budget.
  def self.body_string_param(req, key)
    json_string_param(req, key) || begin
      value = req.POST[key]
      value.is_a?(String) ? value.downcase.strip : nil
    rescue
      nil
    end
  end

  ### Throttle login attempts ###

  # Throttle login attempts by IP address
  # 5 requests per 20 seconds
  throttle("logins/ip", limit: 5, period: 20.seconds) do |req|
    if %w[/api/grid/login /grid/login].include?(req.path) && req.post?
      req.ip
    end
  end

  # Throttle login attempts by hackr_alias parameter
  # 5 requests per 20 seconds per alias
  throttle("logins/alias", limit: 5, period: 20.seconds) do |req|
    if %w[/api/grid/login /grid/login].include?(req.path) && req.post?
      body_string_param(req, "hackr_alias")
    end
  end

  ### Throttle registration attempts ###

  # Prevent registration email spam
  # 3 registration emails per IP per hour
  throttle("registrations/ip", limit: 3, period: 1.hour) do |req|
    if %w[/api/grid/register /grid/register].include?(req.path) && req.post?
      req.ip
    end
  end

  # 3 registration emails per email address per hour
  throttle("registrations/email", limit: 3, period: 1.hour) do |req|
    if %w[/api/grid/register /grid/register].include?(req.path) && req.post?
      body_string_param(req, "email")
    end
  end

  ### Throttle forgot password attempts ###

  # 3 forgot password requests per IP per hour
  throttle("forgot_password/ip", limit: 3, period: 1.hour) do |req|
    if %w[/api/grid/forgot_password /grid/forgot_password].include?(req.path) && req.post?
      req.ip
    end
  end

  # 3 forgot password requests per email per hour
  throttle("forgot_password/email", limit: 3, period: 1.hour) do |req|
    if %w[/api/grid/forgot_password /grid/forgot_password].include?(req.path) && req.post?
      body_string_param(req, "email")
    end
  end

  ### Throttle TOTP verification ###

  # 5 TOTP verify attempts per 2 minutes per IP (brute-force protection)
  throttle("totp_verify/ip", limit: 5, period: 2.minutes) do |req|
    if %w[/api/totp/verify /grid/login/verify].include?(req.path) && req.post?
      req.ip
    end
  end

  # 5 TOTP setup/enable/disable attempts per 15 minutes per IP.
  # HTML two-factor management (Phase 2) shares the bucket; the HTML setup
  # page is a GET and not throttled (require_login, generates nothing
  # persistent). Backup-code regeneration takes password+code, so it's
  # brute-forceable like enable/disable and throttled on both stacks.
  throttle("totp_manage/ip", limit: 5, period: 15.minutes) do |req|
    api_manage = (%w[/api/totp/setup /api/totp/enable /api/totp/regenerate_backup_codes].include?(req.path) && req.post?) ||
      (req.path == "/api/totp/disable" && req.delete?)
    html_manage = (%w[/grid/identity/two-factor/enable /grid/identity/two-factor/backup_codes].include?(req.path) && req.post?) ||
      (req.path == "/grid/identity/two-factor" && req.delete?)
    req.ip if api_manage || html_manage
  end

  ### Throttle token verification ###

  # 10 token verifications per IP per minute
  throttle("verify_token/ip", limit: 10, period: 1.minute) do |req|
    if req.path.start_with?("/api/grid/verify/", "/grid/verify/") && req.get?
      req.ip
    end
  end

  ### Throttle registration completion ###

  # 5 completion attempts per token per hour. The HTML flow carries the
  # token in the path (POST /grid/verify/:token), the API in the body.
  throttle("complete_registration/token", limit: 5, period: 1.hour) do |req|
    if req.path == "/api/grid/complete_registration" && req.post?
      json_string_param(req, "token")
    elsif req.path.start_with?("/grid/verify/") && req.post?
      req.path.delete_prefix("/grid/verify/")
    end
  end

  ### Throttle error reports ###

  # 10 error reports per IP per minute (frontend JS errors)
  throttle("error_report/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.path == "/api/error_report" && req.post?
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
    message = "Rate limit exceeded. Try again in #{retry_after} seconds."

    if request.path.start_with?("/api/")
      [
        429,
        {
          "Content-Type" => "application/json",
          "Retry-After" => retry_after.to_s
        },
        [{error: message, retry_after: retry_after}.to_json]
      ]
    else
      # Hotwire form posts: browsers render the body directly.
      [
        429,
        {
          "Content-Type" => "text/plain",
          "Retry-After" => retry_after.to_s
        },
        [message]
      ]
    end
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
