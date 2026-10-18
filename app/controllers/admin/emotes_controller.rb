# /root/emotes — CRUD for chat emotes (rendered in Uplink + WIRE as :slug:).
# Slug-keyed like releases; purge_image sits outside the main form (nested
# button_to footgun — see gotchas).
class Admin::EmotesController < Admin::ApplicationController
  include Admin::Versionable

  versionable Emote, find_by: :slug

  before_action :set_emote, only: [:edit, :update, :destroy, :purge_image]

  def index
    @emotes = Emote.with_attached_image.order(:slug)
  end

  def new
    @emote = Emote.new
  end

  def create
    @emote = Emote.new(emote_params)
    if @emote.save
      set_flash_success("Emote #{@emote.token} created.")
      redirect_to edit_admin_emote_path(@emote)
    else
      flash.now[:error] = "Failed to create emote: #{@emote.errors.full_messages.join(", ")}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @emote.update(emote_params)
      set_flash_success("Emote #{@emote.token} updated.")
      redirect_to edit_admin_emote_path(@emote)
    else
      flash.now[:error] = "Failed to update emote: #{@emote.errors.full_messages.join(", ")}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    token = @emote.token
    @emote.destroy!
    set_flash_success("Emote #{token} deleted. Copies already rendered into chat history will show as broken images.")
    redirect_to admin_emotes_path
  end

  def purge_image
    @emote.image.purge
    set_flash_success("Image removed from #{@emote.token}. It stops rendering until a new image is uploaded.")
    redirect_to edit_admin_emote_path(@emote)
  end

  private

  def set_emote
    @emote = Emote.find_by!(slug: params[:id])
  end

  def emote_params
    params.require(:emote).permit(:slug, :enabled, :image)
  end
end
