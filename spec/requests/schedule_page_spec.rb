require "rails_helper"

# Server-rendered stream schedule (Hotwire migration Phase 1).
RSpec.describe "Schedule page", type: :request do
  it "renders upcoming and past broadcasts" do
    artist = create(:artist, :thecyberpulse)
    create(:hackr_stream, artist: artist, title: "Friday Transmission",
      scheduled_at: 2.days.from_now)
    create(:hackr_stream, artist: artist, title: "Old Broadcast",
      scheduled_at: 3.days.ago, started_at: 3.days.ago, ended_at: 3.days.ago + 90.minutes,
      is_live: false, vod_url: "https://youtube.example/vod")

    get "/schedule"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("STREAM SCHEDULE")
    expect(response.body).to include("[:: UPCOMING ::]")
    expect(response.body).to include("Friday Transmission")
    expect(response.body).to include("[:: PAST BROADCASTS ::]")
    expect(response.body).to include("Old Broadcast")
    expect(response.body).to include("(1h 30m)")
    expect(response.body).to include("[VOD]")
    expect(response.body).to include("href=\"/thecyberpulse/vidz/#{HackrStream.find_by(title: "Old Broadcast").id}\"")
    expect(response.body).to include(artist.name)
  end

  it "links [VOD] only to recordings that have a page (the TCP + XERAEN archive)" do
    xeraen = create(:hackr_stream, :with_vod, artist: create(:artist, :xeraen), title: "Chaddin Session")
    create(:hackr_stream, :with_vod, artist: create(:artist), title: "Guest Set")

    get "/schedule"

    expect(response.body).to include("Chaddin Session")
    expect(response.body).to include("href=\"/thecyberpulse/vidz/#{xeraen.id}\"")
    expect(response.body).to include("Guest Set")
    expect(response.body.scan("[VOD]").size).to eq(1)
  end

  it "renders empty states" do
    get "/schedule"
    expect(response.body).to include("No upcoming streams scheduled.")
    expect(response.body).to include("No past broadcasts yet.")
  end
end
