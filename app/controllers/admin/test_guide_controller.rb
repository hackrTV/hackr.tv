# Manual testing guide (docs/testing/*.md rendered in-app). Two modes on
# the same pages: browse (Handbook-style article list + standalone
# articles) and wizard (an open ManualTestRun adds per-article
# PASS/FAIL/BLOCKED/SKIP recording + next-article flow + progress).
class Admin::TestGuideController < Admin::ApplicationController
  def index
    @areas = TestGuide.areas
    @total_minutes = TestGuide.total_minutes
    @active_run = ManualTestRun.active
    @results = @active_run&.results_by_slug || {}
    @recent_runs = ManualTestRun.order(created_at: :desc).limit(5)
  end

  def show
    @article = TestGuide.find(params[:slug])
    return redirect_to admin_test_guide_path, alert: "Unknown article." unless @article

    @previous_article, @next_article = TestGuide.neighbors(@article.slug)
    @active_run = ManualTestRun.active
    @result = @active_run&.result_for(@article.slug)
  end

  def record_result
    article = TestGuide.find(params[:slug])
    return redirect_to admin_test_guide_path, alert: "Unknown article." unless article

    run = ManualTestRun.active
    return redirect_to admin_test_guide_article_path(article.slug), alert: "No open test run." unless run

    result = run.manual_test_results.find_or_initialize_by(article_slug: article.slug)
    result.status = params[:status]
    result.notes = params[:notes]

    unless result.save
      return redirect_to admin_test_guide_article_path(article.slug),
        alert: "Could not record result: #{result.errors.full_messages.join(", ")}"
    end

    _, next_article = TestGuide.neighbors(article.slug)
    if next_article
      redirect_to admin_test_guide_article_path(next_article.slug),
        notice: "#{article.title}: #{result.status.upcase} recorded."
    else
      redirect_to admin_test_run_path(run),
        notice: "#{article.title}: #{result.status.upcase} recorded. That was the last article."
    end
  end
end
