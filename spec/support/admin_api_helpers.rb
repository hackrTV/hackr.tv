module AdminApiHelpers
  def create_admin_with_token(traits: [:admin], **attrs)
    hackr = create(:grid_hackr, *traits, **attrs)
    token = hackr.generate_api_token!
    [hackr, token]
  end

  def admin_bearer_token(hackr, token)
    "#{hackr.hackr_alias}:#{token}"
  end

  def admin_headers_for(hackr, token)
    {"Authorization" => "Bearer #{admin_bearer_token(hackr, token)}"}
  end
end

RSpec.configure do |config|
  config.include AdminApiHelpers, type: :controller
  config.include AdminApiHelpers, type: :request
end
