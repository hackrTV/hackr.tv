# System-spec harness (Hotwire migration Phase 0): Capybara + cuprite
# (headless Chrome over CDP, no chromedriver/selenium).
#
# HEADLESS=0 to watch the browser locally.
require "capybara/rspec"
require "capybara/cuprite"

# No system Chrome on this box — use Chrome for Testing (user-local, no
# sudo), installed via:
#   pnpm dlx @puppeteer/browsers install chrome@stable --path ~/.cache/chrome-for-testing
# CHROME_PATH overrides.
chrome_path = ENV["CHROME_PATH"].presence ||
  Dir.glob(File.expand_path("~/.cache/chrome-for-testing/chrome/*/chrome-linux64/chrome")).max

# Registered under a custom name: Rails 8's driven_by(:cuprite) would
# re-register its own :cuprite driver and drop browser_path.
Capybara.register_driver(:hackr_cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    browser_path: chrome_path,
    window_size: [1400, 900],
    browser_options: {
      "no-sandbox" => nil,
      # The player spike toggles playback via a real click, but keep audio
      # unrestricted so timeupdate-based assertions can't flake on policy.
      "autoplay-policy" => "no-user-gesture-required"
    },
    process_timeout: 20,
    timeout: 15,
    headless: %w[0 false].exclude?(ENV.fetch("HEADLESS", "true"))
  )
end

Capybara.default_max_wait_time = 5

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :hackr_cuprite
  end
end
