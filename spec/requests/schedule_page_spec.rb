require "rails_helper"

RSpec.describe "Schedule page", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.zone.local(2026, 11, 6, 12, 0)) { example.run } }

  let(:tcp) { create(:artist, :thecyberpulse) }

  it "renders the console screen with its bar, destinations and prompt" do
    get "/schedule"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('class="console console--schedule" data-controller="terminal" data-boot="pending"')
    expect(response.body).not_to include("chrome-ascii")
    expect(response.body).not_to include('style="')
    expect(response.body).to include('<h1 class="console-bar-title">SCHEDULE</h1>')
    expect(response.body).to include("[&lt;] HOME")
    expect(response.body).to include("[&gt;] VIDZ")
    expect(response.body).to include('data-command="home" href="/"')
    expect(response.body).to include('data-command="vidz" href="/thecyberpulse/vidz"')
    expect(response.body).to include('data-command="tcp" href="/thecyberpulse"')
    expect(response.body).to include('data-command="xeraen" href="/xeraen"')
    expect(response.body).to include("(home vidz tcp xeraen)")
  end

  it "renders empty states" do
    get "/schedule"

    expect(response.body).to include("STANDBY")
    expect(response.body).to include("UNSCHEDULED")
    expect(response.body).to include("NO RECORD")
    expect(response.body).to include("NO TRANSMISSIONS SCHEDULED")
    expect(response.body).to include("NO BROADCASTS ON RECORD")
    expect(response.body).not_to include('data-controller="countdown"')
  end

  it "reads LIVE NOW on the SIGNAL row while a stream is live" do
    create(:hackr_stream, :live, artist: tcp, title: "On Air Now")

    get "/schedule"

    expect(response.body).to include("● LIVE NOW")
    expect(response.body).to include('<a class="console-link" href="/">On Air Now</a>')
    expect(response.body).not_to include("STANDBY")
  end

  it "stamps NEXT TX with the first upcoming stream and mounts its countdown" do
    later = create(:hackr_stream, :scheduled, artist: tcp, title: "Second Signal", scheduled_at: 3.days.from_now)
    first = create(:hackr_stream, :scheduled, artist: tcp, title: "Friday Transmission", scheduled_at: 2.days.from_now)

    get "/schedule"

    expect(response.body).to include(%(data-controller="countdown" data-countdown-deadline-value="#{first.scheduled_at.iso8601}"))
    expect(response.body).to include('data-countdown-target="label"')
    expect(response.body).to include("2126-11-08 12:00")
    expect(response.body).to include("2126-11-09 12:00")
    expect(response.body.index("Friday Transmission")).to be < response.body.index(later.title)
  end

  it "lists upcoming streams with their state word and leaves out expired, cancelled and live ones" do
    create(:hackr_stream, :scheduled, artist: tcp, title: "Friday Transmission")
    create(:hackr_stream, :starting_soon, artist: tcp)
    create(:hackr_stream, :expired_schedule, artist: tcp)
    create(:hackr_stream, :cancelled, artist: tcp)

    get "/schedule"

    expect(response.body).to include("// UPCOMING //")
    expect(response.body).to include('<span class="sc-state sc-state--upcoming">UPCOMING</span>')
    expect(response.body).to include('<span class="sc-state sc-state--soon">STARTING SOON</span>')
    expect(response.body).to include("Friday Transmission")
    expect(response.body).to include("Starting Soon Stream")
    expect(response.body).to include(tcp.name)
    expect(response.body).not_to include("Expired Stream")
    expect(response.body).not_to include("Cancelled Stream")
  end

  it "lists past broadcasts with their stamp and duration, and links LAST TX to its recording" do
    old = create(:hackr_stream, artist: tcp, title: "Old Broadcast",
      started_at: 3.days.ago, ended_at: 3.days.ago + 90.minutes, vod_url: "https://youtube.example/vod")
    create(:hackr_stream, artist: tcp, title: "Never Ended", started_at: 5.days.ago)

    get "/schedule"

    expect(response.body).to include("// PAST BROADCASTS //")
    expect(response.body).to include("2126-11-03 12:00")
    expect(response.body).to include('<span class="sc-dur">1h 30m</span>')
    expect(response.body).to include('<span class="sc-dur"></span>')
    expect(response.body).to include(%(<a class="console-link" href="/thecyberpulse/vidz/#{old.id}">Old Broadcast</a>))
    expect(response.body).to include("· VOD")
    expect(response.body.index("Old Broadcast")).to be < response.body.index("Never Ended")
  end

  it "links [>] VOD only to recordings that have a page (the TCP + XERAEN archive)" do
    xeraen = create(:hackr_stream, :with_vod, artist: create(:artist, :xeraen), title: "Chaddin Session")
    create(:hackr_stream, :with_vod, artist: create(:artist), title: "Guest Set", started_at: 2.days.ago)

    get "/schedule"

    expect(response.body).to include("Chaddin Session")
    expect(response.body).to include("Guest Set")
    expect(response.body).to include(%(<a class="console-link" href="/thecyberpulse/vidz/#{xeraen.id}">[&gt;] VOD</a>))
    expect(response.body.scan("[&gt;] VOD").size).to eq(1)
  end

  it "shows LAST TX unlinked when the newest broadcast has no recording page" do
    create(:hackr_stream, :with_vod, artist: create(:artist), title: "Guest Set")

    get "/schedule"

    expect(response.body).not_to include('href="/thecyberpulse/vidz/')
    expect(response.body).not_to include("· VOD")
  end
end
