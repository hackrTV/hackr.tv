require "rails_helper"

# Server-rendered lore timeline (Hotwire migration Phase 1), backed by
# data/content/timeline.yml via TimelineData.
RSpec.describe "Timeline page", type: :request do
  it "renders all six eras with events from the YAML data" do
    get "/timeline"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("THE TIMELINE")
    TimelineData.eras.each do |era|
      expect(response.body).to include(ERB::Util.html_escape(era["name"]))
      expect(response.body).to include("id=\"#{era["key"]}\"")
    end
    # Spot-check events across eras
    expect(response.body).to include("First Signal Detected")
    expect(response.body).to include("PRISM Discovered")
    expect(response.body).to include("SIGNAL CONTINUES...")
  end

  it "links events to logs and codex entries and marks intercepted files" do
    get "/timeline"

    expect(response.body).to include("INTERCEPTED")
    expect(response.body).to include("CLASSIFIED")
    expect(response.body).to match(%r{href="/logs/[a-z0-9-]+"})
    expect(response.body).to match(%r{href="/codex/[a-z0-9-]+"})
  end
end
