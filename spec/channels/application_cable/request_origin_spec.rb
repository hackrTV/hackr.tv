require "rails_helper"

# Exercises Action Cable's real origin gate (Connection#allow_request_origin?)
# against config.action_cable.allowed_request_origins (config/application.rb).
RSpec.describe ApplicationCable::Connection, "request origin" do
  def origin_allowed?(origin, host: "hackr.tv")
    env = Rack::MockRequest.env_for("/cable", "HTTP_HOST" => host, "HTTPS" => "on")
    env["HTTP_ORIGIN"] = origin if origin
    described_class.new(ActionCable.server, env).send(:allow_request_origin?)
  end

  it "allows the HUD app's local Vite server" do
    expect(origin_allowed?("http://localhost:5173")).to be true
    expect(origin_allowed?("http://127.0.0.1:5174")).to be true
  end

  it "allows same-origin connections" do
    expect(origin_allowed?("https://hackr.tv")).to be true
  end

  it "rejects other origins" do
    expect(origin_allowed?("https://evil.example")).to be false
    expect(origin_allowed?("http://localhost.evil.example:5173")).to be false
    expect(origin_allowed?(nil)).to be false
  end
end
