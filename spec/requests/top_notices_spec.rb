require "rails_helper"

# Top-of-page notices (LIVE NOW banner, NEXT STREAM countdown, prerelease
# banner, flashes, ADMIN PREVIEW) render in the application layout's
# .site-header .top-notices slot — directly below the nav, never
# underneath it. The nav wraps to a variable number of rows, so the slot
# is the only reliable clearance; pages contribute via content_for.
RSpec.describe "Top notices slot", type: :request do
  def main_index(body) = body.index('<main id="main-content">')

  it "renders the slot inside the header, above main, on every page" do
    get "/schedule"

    expect(response).to have_http_status(:ok)
    expect(response.body.index('class="site-header"')).to be < response.body.index('class="top-notices"')
    expect(response.body.index('class="top-notices"')).to be < main_index(response.body)
    expect(response.body).not_to include("bottom-notices")
  end

  it "renders the LIVE NOW banner in the slot on non-home pages, with no spacer" do
    create(:hackr_stream, artist: create(:artist), title: "HEADER SIGNAL", is_live: true,
      live_url: "https://www.youtube.com/embed/test123")

    get "/schedule"

    expect(response.body).to include("[ LIVE NOW ]")
    expect(response.body).to include("HEADER SIGNAL")
    expect(response.body.index('class="live-banner"')).to be < main_index(response.body)
    expect(response.body).not_to include("live-banner-spacer")
  end

  it "renders the NEXT STREAM countdown banner in the slot on the home page" do
    create(:hackr_stream, artist: create(:artist), title: "FUTURE SIGNAL", scheduled_at: 3.days.from_now)

    get "/"

    expect(response.body).to include("NEXT STREAM:")
    expect(response.body.index('class="scheduled-banner"')).to be < main_index(response.body)
  end

  it "renders the prerelease banner in the slot on the login page, with no spacer" do
    stub_const("APP_SETTINGS", APP_SETTINGS.merge(prerelease_mode: "alpha", prerelease_banner_text: "Alpha access only."))

    get "/grid/login"

    expect(response.body).to include("[ALPHA]")
    expect(response.body).to include("Alpha access only.")
    expect(response.body.index('class="prerelease-banner"')).to be < main_index(response.body)
    expect(response.body).not_to include("prerelease-banner-spacer")
  end
end
