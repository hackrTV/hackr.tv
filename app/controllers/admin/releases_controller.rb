class Admin::ReleasesController < Admin::ApplicationController
  before_action :set_release, only: [:edit, :update, :destroy, :purge_cover]

  def index
    @releases = Release.includes(:artist, :tracks, cover_image_attachment: :blob)
      .order("artists.name", :release_date)
  end

  def edit
    @artists = Artist.order(:name)
  end

  def update
    if @release.update(release_params)
      set_flash_success("Release '#{@release.name}' updated successfully!")
      redirect_to edit_admin_release_path(@release)
    else
      @artists = Artist.order(:name)
      flash.now[:error] = "Failed to update release: #{@release.errors.full_messages.join(", ")}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @release.name
    ActiveRecord::Base.transaction do
      @release.tracks.destroy_all
      @release.destroy!
    end
    set_flash_success("Release '#{name}' and all its tracks deleted.")
    redirect_to admin_releases_path
  end

  def purge_cover
    @release.cover_image.purge
    set_flash_success("Cover image removed from '#{@release.name}'.")
    redirect_to edit_admin_release_path(@release)
  end

  private

  def set_release
    @release = Release.find_by(slug: params[:id]) || Release.find(params[:id])
  end

  def release_params
    params.require(:release).permit(
      :name, :slug, :artist_id, :release_type, :release_date,
      :description, :catalog_number, :media_format, :classification,
      :label, :credits, :notes, :coming_soon, :cover_image
    )
  end
end
