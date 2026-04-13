class Admin::HandbookSectionsController < Admin::ApplicationController
  before_action :set_section, only: [:edit, :update, :destroy]

  def index
    @sections = HandbookSection.ordered.includes(:articles)
  end

  def new
    @section = HandbookSection.new(published: true, position: next_position)
  end

  def create
    @section = HandbookSection.new(section_params)
    if @section.save
      set_flash_success("Section '#{@section.name}' created.")
      redirect_to admin_handbook_sections_path
    else
      flash.now[:error] = @section.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @section.update(section_params)
      set_flash_success("Section '#{@section.name}' updated.")
      redirect_to admin_handbook_sections_path
    else
      flash.now[:error] = @section.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @section.name
    @section.destroy!
    set_flash_success("Section '#{name}' deleted.")
    redirect_to admin_handbook_sections_path
  end

  private

  def set_section
    @section = HandbookSection.find_by!(slug: params[:id])
  end

  def section_params
    params.require(:handbook_section).permit(:name, :slug, :icon, :summary, :position, :published)
  end

  def next_position
    (HandbookSection.maximum(:position) || -1) + 1
  end
end
