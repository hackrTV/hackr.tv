# /root/codex_entries — the codex ledger and the entry record as console
# screens (2026-10-31; root_console.css). The record screen is the edit
# screen: show redirects there.
class Admin::CodexEntriesController < Admin::ApplicationController
  include Admin::Versionable

  versionable CodexEntry, find_by: :slug

  before_action :set_entry, only: %i[show edit update destroy]

  def index
    @type_filter = params[:entry_type].presence_in(CodexEntry::ENTRY_TYPES)
    scope = CodexEntry.ordered
    scope = scope.by_type(@type_filter) if @type_filter
    @entries = scope
  end

  def show
    redirect_to edit_admin_codex_entry_path(@entry)
  end

  def new
    @entry = CodexEntry.new(published: false, entry_type: "concept")
  end

  def create
    attrs, json_error = entry_params
    @entry = CodexEntry.new(attrs)

    if json_error
      @entry.valid?
      @entry.errors.add(:metadata, json_error)
      flash.now[:error] = @entry.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
      return
    end

    if @entry.save
      set_flash_success("Codex entry '#{@entry.name}' created.")
      redirect_to edit_admin_codex_entry_path(@entry)
    else
      flash.now[:error] = @entry.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    attrs, json_error = entry_params

    if json_error
      @entry.assign_attributes(attrs)
      @entry.errors.add(:metadata, json_error)
      flash.now[:error] = @entry.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
      return
    end

    if @entry.update(attrs)
      set_flash_success("Codex entry '#{@entry.name}' updated.")
      redirect_to edit_admin_codex_entry_path(@entry)
    else
      flash.now[:error] = @entry.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @entry.name
    @entry.destroy!
    set_flash_success("Codex entry '#{name}' deleted.")
    redirect_to admin_codex_entries_path
  end

  private

  def set_entry
    @entry = CodexEntry.find_by!(slug: params[:id])
  end

  def entry_params
    permitted = params.require(:codex_entry).permit(
      :name, :slug, :entry_type, :summary, :content, :position, :published
    )

    json_source = params[:codex_entry][:metadata_json]
    if json_source.blank?
      permitted[:metadata] = {}
      return [permitted, nil]
    end

    parsed = JSON.parse(json_source)
    unless parsed.is_a?(Hash)
      return [permitted, "must be a JSON object"]
    end

    permitted[:metadata] = parsed
    [permitted, nil]
  rescue JSON::ParserError => e
    [permitted, "is not valid JSON: #{e.message}"]
  end
end
