# Server-rendered Hackr Handbook (Hotwire migration Phase 1) — ports
# HandbookIndexPage/HandbookArticlePage/HandbookLayout/HandbookSidebar.
# Login-gated like the SPA (ProtectedRoute) and the JSON API (which stays).
class HandbookController < ApplicationController
  layout "hotwire"

  before_action :require_login

  KIND_COLORS = {"tutorial" => "#fbbf24", "reference" => "#22d3ee"}.freeze
  ACCENT = "#22d3ee"

  def index
    load_tree
    @recent = HandbookArticle.visible.includes(:handbook_section).recently_updated.limit(5)
  end

  def show
    load_tree
    @article = HandbookArticle.visible.includes(:handbook_section).find_by(slug: params[:slug])

    unless @article
      render :not_found, status: :not_found
      return
    end

    # Prev/next siblings within the section (API show parity)
    section = @article.handbook_section
    siblings = section.articles.published.ordered.to_a
    idx = siblings.index(@article)
    @prev_article = idx&.positive? ? siblings[idx - 1] : nil
    @next_article = (idx && idx < siblings.length - 1) ? siblings[idx + 1] : nil
  end

  private

  # Two queries total, grouped in Ruby (API index parity).
  def load_tree
    @sections = HandbookSection.published.ordered.to_a
    @articles_by_section = HandbookArticle.published.ordered
      .where(handbook_section_id: @sections.map(&:id))
      .group_by(&:handbook_section_id)
  end
end
