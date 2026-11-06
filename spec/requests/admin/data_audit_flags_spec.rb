require "rails_helper"

# /root/data_audit_flags — the data audit's RED FLAGS as a console
# screen (console-ui-for-all-admin Phase 6, 2026-11-04).
RSpec.describe "Admin data audit flags", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  def flag!(title, **attrs)
    DataAuditFlag.create!({fingerprint: Digest::SHA1.hexdigest(title), title: title, check_name: "room_no_exits", domain: "grid",
                           severity: "warning", first_flagged_at: 2.days.ago, last_seen_at: 1.hour.ago}.merge(attrs))
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/data_audit_flags"

    expect(response).not_to have_http_status(:ok)
  end

  it "shows the open counts, the last scan, the filter rows, the ledger with subject links and actions, destinations and the prompt" do
    room = create(:grid_room)
    open = flag!("Room has no exits", severity: "critical", subject_type: "GridRoom", subject_id: room.id)
    acked = flag!("Release has no cover", domain: "music", severity: "info", check_name: "release_no_cover", status: "acknowledged", snooze_until: 1.day.from_now, subject_type: "Release", subject_id: 999_999)
    allow(DataAudit::FlagCache).to receive(:last_scan_at).and_return(Time.zone.parse("2026-11-04 06:00:00"))
    log_in!(admin)

    get "/root/data_audit_flags"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("1 OPEN", "2026-11-04 06:00:00", "/root/data_audit_flags/scan", "[!] RESCAN")
    expect(body).to include("// RED FLAGS · 2 //", "Room has no exits", "CRITICAL", "GRID", "room_no_exits", "/root/grid_rooms/#{room.id}/edit", "[&gt;] EDIT")
    expect(body).to include("Release has no cover", "ACKNOWLEDGED", "until #{acked.snooze_until.strftime("%m-%d %H:%M")}", "MUSIC", "Release#999999")
    expect(body).to include("/root/data_audit_flags/#{open.id}/acknowledge?duration=24h", "[ACK 7D]", "[ACK FOREVER]", "/root/data_audit_flags/#{acked.id}/reopen")
    expect(body).to include('id="check_name"', 'id="search"', "/root/data_audit_flags?status=acknowledged", "/root/data_audit_flags?domain=music", "/root/data_audit_flags?severity=info")
    expect(body).to include("[ERRORS]", "[ANALYTICS]", "[ROOT]")
    expect(body).not_to include("[FLAGS]")
  end

  it "reads ALL CLEAR with no open flags" do
    log_in!(admin)
    get "/root/data_audit_flags"

    expect(response.body).to include("ALL CLEAR", "NEVER", "NO RED FLAGS · ALL CLEAR")
  end

  it "narrows by status, severity, domain, check and search, keeps the others in the links, and ignores unknown values" do
    flag!("grid one")
    flag!("music one", domain: "music", check_name: "release_no_cover")
    flag!("grid acked", status: "acknowledged")
    flag!("grid critical", severity: "critical")
    log_in!(admin)

    get "/root/data_audit_flags", params: {domain: "grid", status: "open", search: "one"}
    body = response.body
    expect(body).to include("// RED FLAGS · 1 //", "grid one", 'value="one"')
    expect(body).not_to include("music one", "grid acked")
    expect(body).to include("/root/data_audit_flags?domain=grid&amp;search=one&amp;severity=critical&amp;status=open")
    expect(body[/<input type="hidden" name="domain"[^>]*>/]).to include('value="grid"')

    get "/root/data_audit_flags", params: {check_name: "release_no_cover"}
    expect(response.body).to include("// RED FLAGS · 1 //", "music one")
    expect(response.body[/<select[^>]*id="check_name".*?<\/select>/m]).to include('<option selected="selected" value="release_no_cover">')

    get "/root/data_audit_flags", params: {status: "acknowledged"}
    expect(response.body).to include("// RED FLAGS · 1 //", "grid acked")
    expect(response.body).not_to include("grid one")

    get "/root/data_audit_flags", params: {severity: "critical"}
    expect(response.body).to include("// RED FLAGS · 1 //", "grid critical")
    expect(response.body).not_to include("grid one")

    get "/root/data_audit_flags", params: {domain: "music"}
    expect(response.body).to include("// RED FLAGS · 1 //", "music one")
    expect(response.body).not_to include("grid one")

    get "/root/data_audit_flags", params: {status: "bogus", check_name: "nope", severity: ["x"], search: {"a" => "b"}}
    expect(response.body).to include("// RED FLAGS · 4 //")
    expect(response.body).not_to include('name="status"', 'name="severity"')

    get "/root/data_audit_flags", params: {offset: 50}
    expect(response.body).to include("// RED FLAGS · 4 //", "grid one")
    expect(response.body).not_to include("NO FLAGS MATCH")
  end

  it "acknowledges, reopens and enqueues a scan, landing back where the button was" do
    flag = flag!("ack me")
    log_in!(admin)

    post "/root/data_audit_flags/#{flag.id}/acknowledge", params: {duration: "7d"}, headers: {"HTTP_REFERER" => "http://www.example.com/root/data_audit_flags?severity=warning"}
    expect(response).to redirect_to("http://www.example.com/root/data_audit_flags?severity=warning")
    follow_redirect!
    expect(response.body).to include("[OK]", "Flag acknowledged until", "ACKNOWLEDGED", "[REOPEN]")
    expect(flag.reload.status).to eq("acknowledged")
    expect(flag.snooze_until).to be_within(1.minute).of(7.days.from_now)

    post "/root/data_audit_flags/#{flag.id}/reopen"
    expect(response).to redirect_to("/root/data_audit_flags")
    expect(flag.reload.status).to eq("open")

    expect { post "/root/data_audit_flags/scan" }.to have_enqueued_job(DataAudit::ScanJob)
    expect(response).to redirect_to("/root/data_audit_flags")
    follow_redirect!
    expect(response.body).to include("[OK]", "Audit scan enqueued")
  end
end
