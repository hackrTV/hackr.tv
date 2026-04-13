module Api
  class HandbookController < ApplicationController
    include GridAuthentication

    before_action :require_login_api

    # GET /api/handbook
    # Full tree payload: sections with their articles. One round-trip powers
    # both the sidebar and the landing-page TOC. Two queries total (sections,
    # articles) — grouped in Ruby to avoid N+1 from chained association scopes.
    def index
      sections = HandbookSection.published.ordered.to_a
      articles_by_section = HandbookArticle.published.ordered
        .where(handbook_section_id: sections.map(&:id))
        .group_by(&:handbook_section_id)

      render json: {
        sections: sections.map { |section|
          {
            id: section.id,
            slug: section.slug,
            name: section.name,
            icon: section.icon,
            summary: section.summary,
            position: section.position,
            articles: (articles_by_section[section.id] || []).map { |article|
              serialize_article_summary(article)
            }
          }
        }
      }
    end

    # GET /api/handbook/recent
    # Last N published articles by updated_at. Used by the landing-page
    # "Recently Updated" panel.
    def recent
      limit = [(params[:limit] || 5).to_i, 20].min
      articles = HandbookArticle.published
        .includes(:handbook_section)
        .recently_updated
        .limit(limit)

      render json: articles.map { |article|
        serialize_article_summary(article).merge(
          section: {slug: article.handbook_section.slug, name: article.handbook_section.name}
        )
      }
    end

    # GET /api/handbook/mappings
    # slug -> title map for any future wiki-link style cross-references.
    def mappings
      mapping = HandbookArticle.published.pluck(:slug, :title).to_h
      render json: mapping
    end

    # GET /api/handbook/:slug
    # Full article with section context and prev/next siblings within the
    # same section for GitBook-style navigation at the bottom of each page.
    def show
      article = HandbookArticle.published.find_by!(slug: params[:slug])
      section = article.handbook_section
      siblings = section.articles.published.ordered.to_a
      idx = siblings.index(article)
      prev_article = idx&.positive? ? siblings[idx - 1] : nil
      next_article = (idx && idx < siblings.length - 1) ? siblings[idx + 1] : nil

      render json: {
        id: article.id,
        slug: article.slug,
        title: article.title,
        kind: article.kind,
        difficulty: article.difficulty,
        summary: article.summary,
        body: article.body,
        metadata: article.metadata,
        position: article.position,
        updated_at: article.updated_at,
        section: {
          id: section.id,
          slug: section.slug,
          name: section.name,
          icon: section.icon
        },
        prev_article: prev_article && {slug: prev_article.slug, title: prev_article.title},
        next_article: next_article && {slug: next_article.slug, title: next_article.title}
      }
    rescue ActiveRecord::RecordNotFound
      render json: {error: "Handbook article not found"}, status: :not_found
    end

    private

    def serialize_article_summary(article)
      {
        id: article.id,
        slug: article.slug,
        title: article.title,
        kind: article.kind,
        difficulty: article.difficulty,
        summary: article.summary,
        position: article.position,
        updated_at: article.updated_at
      }
    end
  end
end
