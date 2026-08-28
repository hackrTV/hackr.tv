require "rails_helper"

# /root/test_guide — the manual testing guide UI (docs/testing/*.md
# rendered in-app) + wizard run tracking.
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

  it "renders the article index grouped by area with the start form" do
    log_in!(admin)
    get "/root/test_guide"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Manual Testing Guide")
    expect(response.body).to include("START TEST RUN")
    expect(response.body).to include("Using This Guide")
    expect(response.body).to include("BREACH")
    expect(response.body).to include("<h2>The Grid</h2>")
  end

  it "renders an article with prev/next navigation and step markers" do
    log_in!(admin)
    get "/root/test_guide/36_breach"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("BREACH")
    expect(response.body).to include("35_tactical_panels")
    expect(response.body).to include("37_grid_meta_pages")
    expect(response.body).to include("tg-step")
  end

  it "redirects unknown slugs" do
    log_in!(admin)
    get "/root/test_guide/definitely-not-real"
    expect(response).to redirect_to("/root/test_guide")
  end

  describe "wizard flow" do
    it "starts a run, records results, advances, and reports" do
      log_in!(admin)

      # Start: lands on the first article
      post "/root/test_runs", params: {label: "spec run"}
      run = ManualTestRun.last
      expect(run.label).to eq("spec run")
      expect(response).to redirect_to("/root/test_guide/00_using_this_guide")

      # Article shows the recording controls for the open run
      get "/root/test_guide/00_using_this_guide"
      expect(response.body).to include("spec run")
      expect(response.body).to include("PASS")

      # PASS advances to the next article
      post "/root/test_guide/00_using_this_guide/result", params: {status: "pass"}
      expect(response).to redirect_to("/root/test_guide/01_environment_setup")
      expect(run.result_for("00_using_this_guide").status).to eq("pass")

      # FAIL with notes; re-recording upserts (no duplicate row)
      post "/root/test_guide/01_environment_setup/result", params: {status: "fail", notes: "step 3 empty world"}
      post "/root/test_guide/01_environment_setup/result", params: {status: "pass", notes: "fixed"}
      expect(run.manual_test_results.where(article_slug: "01_environment_setup").count).to eq(1)
      expect(run.result_for("01_environment_setup").status).to eq("pass")

      # Invalid status rejected
      post "/root/test_guide/02_cross_cutting_invariants/result", params: {status: "meh"}
      expect(flash[:alert]).to include("Could not record")

      # Run dashboard shows progress + failures section when present
      post "/root/test_guide/02_cross_cutting_invariants/result", params: {status: "fail", notes: "player died on nav"}
      get "/root/test_runs/#{run.id}"
      expect(response.body).to include("player died on nav")
      expect(response.body).to include("Failures")

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
    end

    it "refuses recording without an open run" do
      log_in!(admin)
      post "/root/test_guide/00_using_this_guide/result", params: {status: "pass"}
      expect(flash[:alert]).to include("No open test run")
    end
  end
end
