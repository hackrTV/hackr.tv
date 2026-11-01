require "rails_helper"

# /root/pulse_wire + /pulse_drops — the WIRE's moderation ledgers as
# console screens (console-ui-for-all-admin Phase 2, 2026-10-31).
RSpec.describe "Admin PulseWire", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, hackr_alias: "ghostline", password: "hackthegrid") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/pulse_wire"

    expect(response).not_to have_http_status(:ok)
  end

  describe "the WIRE ledger" do
    it "numbers every pulse with its actions, the filter rows, the bulk hooks the script targets, destinations and the prompt" do
      live = create(:pulse, grid_hackr: operative, content: "signal from the undercity")
      dropped = create(:pulse, :pulse_dropped, grid_hackr: operative, content: "noise on the line")
      log_in!(admin)

      get "/root/pulse_wire"

      body = response.body
      expect(response).to have_http_status(:ok)
      expect(body).to be_console_clean
      expect(body).to include("PULSEWIRE", "2 pulses", "1 dropped", "// FILTER //", "// PULSES //")
      expect(body).to include("[01]", "[02]", "signal from the undercity", "noise on the line", "@ghostline")
      expect(body).to include('data-command="01"', %(href="/wire/pulse/#{live.id}"))
      expect(body).to include(%(action="/root/pulse_wire/#{live.id}/pulse_drop"), %(action="/root/pulse_wire/#{dropped.id}/restore"), %(action="/root/pulse_wire/#{live.id}"))
      expect(body).to include('id="select-all"', 'id="selected-count"', 'id="bulk-pulse-drop"', 'id="bulk-delete"', %(class="pulse-checkbox rc-check-input" value="#{live.id}"))
      expect(body).to include('name="username"', 'name="search"', 'name="start_date"', 'name="end_date"', "[FILTER]", "[x] CLEAR")
      expect(body).to include("[DROPS]", "[UPLINK]", "[GRID]").and include("a pulse number")
      expect(body).not_to include("[WIRE]")
    end

    it "filters by status, hackr and content, the STATUS links keeping the other filters" do
      create(:pulse, grid_hackr: operative, content: "signal from the undercity")
      create(:pulse, :pulse_dropped, grid_hackr: operative, content: "noise on the line")
      create(:pulse, content: "someone else entirely")
      log_in!(admin)

      get "/root/pulse_wire", params: {status: "dropped", username: "ghostline"}

      body = response.body
      expect(body).to include("noise on the line", "1 pulse", "filtered")
      expect(body).not_to include("signal from the undercity", "someone else entirely")
      expect(body).to include('href="/root/pulse_wire?status=active&amp;username=ghostline"')
      expect(body).to include('<input type="hidden" name="status" id="status" value="dropped"')

      get "/root/pulse_wire", params: {search: "nothing like it"}
      expect(response.body).to include("NO PULSES MATCH")

      # An unknown status filters nothing, so it reads unfiltered with ALL lit and is not carried forward.
      get "/root/pulse_wire", params: {status: "bogus"}
      body = response.body
      expect(body).to include("3 pulses", %(class="rc-btn rc-btn--on" aria-current="page" href="/root/pulse_wire">ALL</a>))
      expect(body).not_to include("filtered", 'name="status"')
    end

    it "drops, restores and deletes with [OK] replies" do
      pulse = create(:pulse, grid_hackr: operative)
      log_in!(admin)

      post "/root/pulse_wire/#{pulse.id}/pulse_drop", headers: {"HTTP_REFERER" => "/root/pulse_wire"}
      follow_redirect!
      expect(response.body).to include("[OK]", "Pulse by @ghostline has been pulse-dropped.")
      expect(pulse.reload.pulse_dropped).to be(true)

      post "/root/pulse_wire/#{pulse.id}/restore"
      follow_redirect!
      expect(response.body).to include("[OK]", "has been restored.")

      delete "/root/pulse_wire/#{pulse.id}"
      expect(Pulse.exists?(pulse.id)).to be(false)
    end
  end

  it "lists the dropped pulses with restore and delete" do
    dropped = create(:pulse, :pulse_dropped, grid_hackr: operative, content: "noise on the line")
    create(:pulse, grid_hackr: operative, content: "signal from the undercity")
    log_in!(admin)

    get "/root/pulse_wire/pulse_drops"

    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("PULSE DROPS", "1 dropped pulse", "// DROPPED //", "[01]", "noise on the line", "@ghostline")
    expect(body).not_to include("signal from the undercity")
    expect(body).to include(%(action="/root/pulse_wire/#{dropped.id}/restore"), %(action="/root/pulse_wire/#{dropped.id}"), "[RESTORE]", "[DEL]")
    expect(body).to include("[WIRE]")
    expect(body).not_to include("[DROPS]")
  end
end
