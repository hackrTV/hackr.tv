module Api
  class CodexController < ApplicationController
    # GET /api/codex
    # Returns all published codex entries with optional type filtering
    def index
      @entries = CodexEntry.published.ordered

      # Filter by entry_type if provided
      if params[:entry_type].present? && CodexEntry::ENTRY_TYPES.include?(params[:entry_type])
        @entries = @entries.by_type(params[:entry_type])
      end

      # Search by name or summary if query provided
      if params[:query].present?
        query = "%#{params[:query]}%"
        @entries = @entries.where("name LIKE ? OR summary LIKE ?", query, query)
      end

      render json: @entries.map { |entry|
        {
          id: entry.id,
          name: entry.name,
          slug: entry.slug,
          entry_type: entry.entry_type,
          summary: entry.summary,
          position: entry.position,
          metadata: entry.metadata
        }
      }
    end

    # GET /api/codex/:slug
    # Returns a single published codex entry with full content
    def show
      @entry = CodexEntry.published.find_by!(slug: params[:slug])

      render json: {
        id: @entry.id,
        name: @entry.name,
        slug: @entry.slug,
        entry_type: @entry.entry_type,
        summary: @entry.summary,
        content: @entry.content,
        metadata: @entry.metadata,
        position: @entry.position,
        created_at: @entry.created_at,
        updated_at: @entry.updated_at
      }
    rescue ActiveRecord::RecordNotFound
      render json: {error: "Codex entry not found"}, status: :not_found
    end
  end
end
