module AdminApiHelpers
  def admin_token
    "test_admin_api_token_secret"
  end

  def admin_headers
    {"Authorization" => "Bearer #{admin_token}"}
  end
end

RSpec.configure do |config|
  config.include AdminApiHelpers, type: :controller
  config.include AdminApiHelpers, type: :request
end
