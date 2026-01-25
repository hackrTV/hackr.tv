# Read-only controller - Codex entries are managed via YAML files
# Edit data/content/codex.yml and run: rails data:codex
class Admin::CodexEntriesController < Admin::ApplicationController
  def index
    @codex_entries = CodexEntry.ordered
    @codex_entries = @codex_entries.by_type(params[:entry_type]) if params[:entry_type].present?
  end
end
