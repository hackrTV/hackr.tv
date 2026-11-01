require "rails_helper"

# /root/hackr_streams — the streams ledger (with GO LIVE / END / CANCEL
# on its rows) and the stream record as console screens
# (console-ui-for-all-admin Phase 1, 2026-10-31).
RSpec.describe "Admin hackr streams", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }
  let!(:artist) { create(:artist, name: "XERAEN", slug: "xeraen-stream") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/hackr_streams"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the streams with LIVE NOW, their states and the actions each state allows" do
    live = create(:hackr_stream, :live, artist: artist, title: "On Air")
    scheduled = create(:hackr_stream, :scheduled, artist: artist)
    cancelled = create(:hackr_stream, :cancelled, artist: artist)
    log_in!(admin)

    get "/root/hackr_streams"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include("ON AIR", "LIVE NOW", "On Air")
    expect(body).to include("[01]", "[02]", "[03]", 'data-command="03"')
    expect(body).to include("LIVE", "SCHEDULED", "CANCELLED")
    expect(body).to include(%(action="/root/hackr_streams/#{live.id}/end_stream"))
    expect(body).to include(%(action="/root/hackr_streams/#{scheduled.id}/go_live"), %(action="/root/hackr_streams/#{scheduled.id}/cancel"))
    expect(body).not_to include(%(action="/root/hackr_streams/#{cancelled.id}/go_live"))
    expect(body).to include('data-confirm="End this livestream?"')
    expect(body).not_to include("[STREAMS]")
    expect(body).to include("[PLAYLISTS]", "type a stream number")
  end

  it "says when nothing is live" do
    log_in!(admin)

    get "/root/hackr_streams"

    expect(response.body).to include("NO ACTIVE LIVESTREAM", "NO STREAMS ON RECORD")
  end

  it "redirects show to the record screen, which carries the fields, the state and the delete form" do
    stream = create(:hackr_stream, :cancelled, artist: artist)
    log_in!(admin)

    get "/root/hackr_streams/#{stream.id}"
    expect(response).to redirect_to("/root/hackr_streams/#{stream.id}/edit")

    get "/root/hackr_streams/#{stream.id}/edit"
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include(%(action="/root/hackr_streams/#{stream.id}"), 'value="Cancelled Stream"')
    expect(body).to include('name="hackr_stream[scheduled_at]"', 'name="hackr_stream[started_at]"', 'name="hackr_stream[ended_at]"', 'name="hackr_stream[vod_url]"')
    expect(body).to include("// SCHEDULE //", "CANCELLED", "STATE")
    expect(body).to include('form="delete-stream"', 'id="delete-stream"')
  end

  it "saves the record and stays on it; a rejected save is a 422" do
    stream = create(:hackr_stream, artist: artist, started_at: nil)
    log_in!(admin)

    patch "/root/hackr_streams/#{stream.id}", params: {hackr_stream: {artist_id: artist.id, title: "Fracture Tour", live_url: "https://www.youtube.com/embed/abc", vod_url: "", scheduled_at: "2026-11-01T20:00"}}
    expect(response).to redirect_to("/root/hackr_streams/#{stream.id}/edit")
    follow_redirect!
    expect(response.body).to include("[OK]", "Stream updated successfully!")
    expect(stream.reload).to have_attributes(title: "Fracture Tour", live_url: "https://www.youtube.com/embed/abc")

    patch "/root/hackr_streams/#{stream.id}", params: {hackr_stream: {title: "x" * 300}}
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]", "Failed to update stream")
  end

  it "keeps a cancelled stream cancelled when the form resubmits its schedule, and clears it on a new one" do
    stream = create(:hackr_stream, :cancelled, artist: artist)
    resubmitted = stream.scheduled_at.strftime("%Y-%m-%dT%H:%M:%S") # what the datetime-local field posts back
    log_in!(admin)

    patch "/root/hackr_streams/#{stream.id}", params: {hackr_stream: {title: "Retitled", scheduled_at: resubmitted}}
    expect(response).to redirect_to("/root/hackr_streams/#{stream.id}/edit")
    expect(stream.reload).to have_attributes(title: "Retitled", cancelled_at: be_present)

    patch "/root/hackr_streams/#{stream.id}", params: {hackr_stream: {scheduled_at: (stream.scheduled_at + 1.day).strftime("%Y-%m-%dT%H:%M")}}
    expect(stream.reload.cancelled_at).to be_nil
  end

  it "creates a stream and opens its record; go live / end run from the ledger" do
    log_in!(admin)

    get "/root/hackr_streams/new"
    expect(response.body).to be_console_clean

    post "/root/hackr_streams", params: {hackr_stream: {artist_id: artist.id, title: "Fresh", live_url: "https://www.youtube.com/embed/fresh"}}
    stream = HackrStream.find_by!(title: "Fresh")
    expect(response).to redirect_to("/root/hackr_streams/#{stream.id}/edit")

    post "/root/hackr_streams/#{stream.id}/go_live"
    expect(response).to redirect_to("/root/hackr_streams")
    expect(stream.reload.is_live).to be(true)

    expect { delete "/root/hackr_streams/#{stream.id}" }.to change(HackrStream, :count).by(-1)
  end
end
