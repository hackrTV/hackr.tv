class Admin::TestRunsController < Admin::ApplicationController
  def index
    @runs = ManualTestRun.includes(:grid_hackr, :manual_test_results).order(created_at: :desc)
    @total_articles = TestGuide.articles.size
  end

  def create
    label = params[:label].presence || "Test run #{Time.current.strftime("%Y-%m-%d %H:%M")}"
    run = ManualTestRun.create!(label: label, grid_hackr: current_hackr)
    first = TestGuide.articles.first
    redirect_to admin_test_guide_article_path(first.slug),
      flash: {success: "Run \"#{run.label}\" started."}
  end

  def show
    @run = ManualTestRun.find(params[:id])
    @articles = TestGuide.articles
    @results = @run.results_by_slug
    @failures = @results.values.select { |r| r.status == "fail" }
  end

  def update
    run = ManualTestRun.find(params[:id])
    run.update!(completed_at: Time.current)
    redirect_to admin_test_run_path(run), flash: {success: "Run marked complete."}
  end

  def destroy
    run = ManualTestRun.find(params[:id])
    run.destroy!
    redirect_to admin_test_runs_path, flash: {success: "Run deleted."}
  end
end
