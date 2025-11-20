class Admin::CodexEntriesController < Admin::ApplicationController
  before_action :set_codex_entry, only: [:edit, :update, :destroy]

  def index
    @codex_entries = CodexEntry.ordered
    @codex_entries = @codex_entries.by_type(params[:entry_type]) if params[:entry_type].present?
  end

  def new
    @codex_entry = CodexEntry.new
  end

  def create
    @codex_entry = CodexEntry.new(codex_entry_params)
    process_metadata

    if @codex_entry.save
      set_flash_success("Codex entry '#{@codex_entry.name}' created successfully!")
      redirect_to admin_codex_entries_path
    else
      flash.now[:error] = "Failed to create codex entry: #{@codex_entry.errors.full_messages.join(", ")}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    process_metadata

    if @codex_entry.update(codex_entry_params)
      set_flash_success("Codex entry '#{@codex_entry.name}' updated successfully!")
      redirect_to admin_codex_entries_path
    else
      flash.now[:error] = "Failed to update codex entry: #{@codex_entry.errors.full_messages.join(", ")}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @codex_entry.name
    @codex_entry.destroy
    set_flash_success("Codex entry '#{name}' deleted successfully!")
    redirect_to admin_codex_entries_path
  end

  private

  def set_codex_entry
    @codex_entry = CodexEntry.find_by!(slug: params[:id])
  end

  def codex_entry_params
    params.require(:codex_entry).permit(
      :name,
      :slug,
      :entry_type,
      :summary,
      :content,
      :published,
      :position
    )
  end

  def process_metadata
    # Process metadata JSON
    if params[:codex_entry][:metadata_json].present?
      begin
        metadata = {}
        params[:codex_entry][:metadata_json].each do |key, value|
          metadata[key] = value if value.present?
        end
        @codex_entry.metadata = metadata.presence || {}
      rescue => e
        Rails.logger.error "Failed to process metadata: #{e.message}"
        @codex_entry.metadata = {}
      end
    end
  end
end
