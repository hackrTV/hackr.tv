require "rails_helper"

# /root/test_runs — the manual test runs' ledger and run readout as
# console screens (console-ui-for-all-admin Phase 6, 2026-11-04). The
# wizard round-trip itself is spec/requests/admin/test_guide_spec.rb.
RSpec.describe "Admin test runs", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, hackr_alias: "xeraen", password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }
  let(:articles) { TestGuide.articles }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/test_runs"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the runs numbered with their counts, destinations and the prompt" do
    done = ManualTestRun.create!(label: "staging pass", grid_hackr: admin, completed_at: 1.day.ago, created_at: 2.days.ago)
    done.manual_test_results.create!(article_slug: articles[0].slug, status: "pass")
    done.manual_test_results.create!(article_slug: articles[1].slug, status: "fail", notes: "nav died")
    open = ManualTestRun.create!(label: "tonight", grid_hackr: admin)
    log_in!(admin)

    get "/root/test_runs"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("2 runs", "1 open", "[01]", "/root/test_runs/#{open.id}", "tonight", "OPEN", "[02]", "/root/test_runs/#{done.id}", "staging pass", "COMPLETE", "by xeraen")
    expect(body).to include('data-command="01"', 'data-command="02"', "2 / #{articles.size}", ">1<", ">#{done.progress(articles.size)}%<")
    expect(body).to include("[GUIDE]", "[ERRORS]", "[ROOT]")
    expect(body).not_to include("[RUNS]", "[DEL]")
    expect(body).to include("type a run number")
  end

  it "reads NO RUNS YET with none" do
    log_in!(admin)
    get "/root/test_runs"

    expect(response.body).to include("NO RUNS YET", "start one from the guide")
  end

  it "shows a run's readout with its results, failures, the articles numbered through, and the actions" do
    run = ManualTestRun.create!(label: "tonight", grid_hackr: admin)
    run.manual_test_results.create!(article_slug: articles[0].slug, status: "pass")
    run.manual_test_results.create!(article_slug: articles[1].slug, status: "fail", notes: "step 3: the player stopped on nav")
    run.manual_test_results.create!(article_slug: articles[2].slug, status: "blocked", notes: "no world data")
    log_in!(admin)

    get "/root/test_runs/#{run.id}"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("RUN ##{run.id}", "by xeraen", "tonight", ">OPEN<")
    expect(body).to include("// RESULTS //", "UNRECORDED", "#{articles.size - 3}<")
    expect(body).to include("/root/test_runs/#{run.id}", "[MARK RUN COMPLETE]", 'form="delete-run"', "[DELETE RUN]")
    expect(body[/<form[^>]*id="delete-run"[^>]*>/]).to include('data-confirm="Delete run &quot;tonight&quot; and its results?"')
    expect(body).to include("// FAILURES · 1 //", "step 3: the player stopped on nav", "/root/test_guide/#{articles[1].slug}")
    expect(body).to include("// ARTICLES //", "[01]", articles[0].title, "PASS", "[03]", "BLOCKED", "no world data", "[#{format("%02d", articles.size)}]")
    expect(body).to include("[&lt;] RUNS", 'data-command="back"', "[&gt;] GUIDE", "[GUIDE]", 'data-command="01"')
    expect(body).not_to include("[RUNS]")
  end

  it "marks a run complete and deletes it with its results" do
    run = ManualTestRun.create!(label: "tonight", grid_hackr: admin)
    run.manual_test_results.create!(article_slug: articles[0].slug, status: "pass")
    log_in!(admin)

    patch "/root/test_runs/#{run.id}"
    expect(response).to redirect_to("/root/test_runs/#{run.id}")
    follow_redirect!
    expect(response.body).to include("[OK]", "Run marked complete.", ">COMPLETE<")
    expect(response.body).not_to include("[MARK RUN COMPLETE]")
    expect(run.reload).to be_completed

    expect { delete "/root/test_runs/#{run.id}" }.to change(ManualTestResult, :count).by(-1)
    expect(response).to redirect_to("/root/test_runs")
    follow_redirect!
    expect(response.body).to include("[OK]", "Run deleted.")
    expect(ManualTestRun.exists?(run.id)).to be(false)
  end
end
