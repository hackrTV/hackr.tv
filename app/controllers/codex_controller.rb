# Server-rendered Codex wiki (Hotwire migration Phase 1) — ports
# CodexIndexPage.tsx + CodexEntryPage.tsx. Type filter + search are
# client-side over the fully rendered index (matches the SPA, which loaded
# all entries once) via codex_filter_controller.ts. The JSON API stays.
class CodexController < ApplicationController
  layout "hotwire"

  ENTRY_TYPE_COLORS = {
    "person" => "#a78bfa", "organization" => "#60a5fa", "event" => "#f472b6",
    "location" => "#34d399", "technology" => "#fbbf24", "faction" => "#f87171",
    "band" => "#fb923c", "item" => "#a3e635", "concept" => "#22d3ee"
  }.freeze

  ENTRY_TYPE_ICONS = {
    "person" => "👤", "organization" => "🏢", "event" => "📅", "location" => "📍",
    "technology" => "⚙️", "faction" => "⚔️", "band" => "🎸", "item" => "📦", "concept" => "💡"
  }.freeze

  def index
    @entries = CodexEntry.published.ordered.to_a
    @entry_types = @entries.map(&:entry_type).uniq
    @type_counts = @entries.group_by(&:entry_type).transform_values(&:size)
  end

  def show
    @entry = CodexEntry.published.find_by(slug: params[:slug])

    unless @entry
      render :not_found, status: :not_found
      return
    end

    # Read credit inline (the SPA fired POST /api/codex/:slug/read)
    if current_hackr
      CodexEntryRead.record!(current_hackr, @entry)
      checker = Grid::AchievementChecker.new(current_hackr)
      checker.check("codex_entries_read")
      checker.check("codex_entries_read_all")
    end
  end
end
