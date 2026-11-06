require "rails_helper"

# /root/test_guide — the manual testing guide UI (docs/testing/*.md
# rendered in-app) + wizard run tracking, as console screens since
# console-ui-for-all-admin Phase 6 (2026-11-04); the article body stays
# the serif reading island inside the shell.
RSpec.describe "Admin test guide", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/test_guide"
    expect(response).not_to have_http_status(:ok)
  end

  it "renders the article ledgers by area, numbered through, with the start form, destinations and the prompt" do
    log_in!(admin)
    get "/root/test_guide"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("TEST GUIDE", "// START A RUN //", 'id="label"', "[START TEST RUN]", "/root/test_runs")
    expect(body).to include("// SETUP //", "// THE GRID //", "[01]", 'data-command="01"', "Using This Guide", "/root/test_guide/00_using_this_guide", "BREACH", "[#{format("%02d", TestGuide.articles.size)}]", "~12 MIN")
    expect(body).to include("[RUNS]", "[ERRORS]", "[ROOT]")
    expect(body).not_to include("[GUIDE]", "// ACTIVE RUN //", "RUN OPEN")
    expect(body).to include("type an article number")
  end

  it "renders an article inside the console shell with prev / next, the serif body and step markers" do
    log_in!(admin)
    get "/root/test_guide/36_breach"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body.split('<div class="tguide-article"', 2).first).to be_console_clean
    expect(body).to include("BREACH", "GUIDE · THE GRID", "/root/test_guide/35_tactical_panels", "[&lt;] PREV", 'data-command="prev"', "/root/test_guide/37_grid_meta_pages", "[&gt;] NEXT", 'data-command="next"', "[&lt;] GUIDE", 'data-command="back"')
    expect(body).to include('<div class="tguide-article" id="test-guide-article" data-run-id="">', "tg-step", "admin_test_guide")
    expect(body).not_to include("// RECORD //", "[PASS]")
    expect(body).to include("(prev next back errors flags analytics runs root)")
  end

  it "redirects unknown slugs with [ERR]" do
    log_in!(admin)
    get "/root/test_guide/definitely-not-real"
    expect(response).to redirect_to("/root/test_guide")
    follow_redirect!
    expect(response.body).to include("[ERR]", "Unknown article.")
  end

  describe "wizard flow" do
    it "starts a run, records results, advances, and reports" do
      log_in!(admin)

      # Start: lands on the first article with [OK]
      post "/root/test_runs", params: {label: "spec run"}
      run = ManualTestRun.last
      expect(run.label).to eq("spec run")
      expect(response).to redirect_to("/root/test_guide/00_using_this_guide")
      follow_redirect!
      expect(response.body).to include("[OK]", "Run &quot;spec run&quot; started.")

      # Article shows the recording controls for the open run
      get "/root/test_guide/00_using_this_guide"
      body = response.body
      expect(body).to include("// RECORD //", "spec run", "/root/test_runs/#{run.id}", "// NOTES //", 'id="notes"', "[PASS]", "[FAIL]", "[BLOCKED]", "[SKIP]", "[&gt;] SKIP AHEAD")
      expect(body).to include("/root/test_guide/00_using_this_guide/result")

      # The index reads the active run
      get "/root/test_guide"
      expect(response.body).to include("RUN OPEN", "// ACTIVE RUN //", "0 / #{TestGuide.articles.size} recorded", "next: USING THIS GUIDE", "[&gt;] CONTINUE", 'data-command="continue"', "[&gt;] RUN", 'data-command="run"', "(continue run")
      expect(response.body).not_to include("[START TEST RUN]")

      # PASS advances to the next article
      post "/root/test_guide/00_using_this_guide/result", params: {status: "pass"}
      expect(response).to redirect_to("/root/test_guide/01_environment_setup")
      expect(run.result_for("00_using_this_guide").status).to eq("pass")
      follow_redirect!
      expect(response.body).to include("[OK]", "Using This Guide: PASS recorded.")

      # FAIL with notes; re-recording upserts (no duplicate row); the article shows its status
      post "/root/test_guide/01_environment_setup/result", params: {status: "fail", notes: "step 3 empty world"}
      post "/root/test_guide/01_environment_setup/result", params: {status: "pass", notes: "fixed"}
      expect(run.manual_test_results.where(article_slug: "01_environment_setup").count).to eq(1)
      expect(run.result_for("01_environment_setup").status).to eq("pass")
      get "/root/test_guide/01_environment_setup"
      expect(response.body).to include("this article", ">PASS<", "fixed</textarea>")

      # Invalid status rejected
      post "/root/test_guide/02_cross_cutting_invariants/result", params: {status: "meh"}
      expect(flash[:error]).to include("Could not record")

      # Run dashboard shows progress + failures section when present
      post "/root/test_guide/02_cross_cutting_invariants/result", params: {status: "fail", notes: "player died on nav"}
      get "/root/test_runs/#{run.id}"
      expect(response.body).to include("player died on nav", "// FAILURES · 1 //")

      # Complete the run; recording controls disappear (no open run)
      patch "/root/test_runs/#{run.id}"
      expect(run.reload).to be_completed
      get "/root/test_guide/00_using_this_guide"
      expect(response.body).not_to include("spec run")

      # History lists it; delete removes results too
      get "/root/test_runs"
      expect(response.body).to include("spec run")
      expect { delete "/root/test_runs/#{run.id}" }.to change(ManualTestResult, :count).to(0)
    end

    it "records on the LAST article and lands on the run dashboard" do
      log_in!(admin)
      post "/root/test_runs", params: {label: "tail run"}
      run = ManualTestRun.last
      last_slug = TestGuide.articles.last.slug

      post "/root/test_guide/#{last_slug}/result", params: {status: "skip"}
      expect(response).to redirect_to("/root/test_runs/#{run.id}")
      follow_redirect!
      expect(response.body).to include("[OK]", "That was the last article.")
    end

    it "refuses recording without an open run" do
      log_in!(admin)
      post "/root/test_guide/00_using_this_guide/result", params: {status: "pass"}
      expect(flash[:error]).to include("No open test run")
    end
  end
end
