class Admin::HandbookArticlesController < Admin::ApplicationController
  include Admin::Versionable
  versionable HandbookArticle, find_by: :slug

  before_action :set_article, only: [:edit, :update, :destroy]

  def index
    @articles = HandbookArticle.includes(:handbook_section).order("handbook_sections.position, handbook_articles.position, handbook_articles.title").references(:handbook_section)
    @articles = @articles.where(handbook_section_id: params[:section_id]) if params[:section_id].present?
    @sections = HandbookSection.ordered
  end

  def new
    @article = HandbookArticle.new(
      kind: "reference",
      published: true,
      position: next_position(params[:handbook_section_id] || params[:section_id]),
      handbook_section_id: params[:handbook_section_id] || params[:section_id]
    )
    @sections = HandbookSection.ordered
  end

  def create
    attrs, json_error = article_params
    @article = HandbookArticle.new(attrs)

    if json_error.nil? && @article.save
      set_flash_success("Article '#{@article.title}' created.")
      redirect_to admin_handbook_articles_path(section_id: @article.handbook_section_id)
      return
    end

    if json_error
      @article.valid?
      @article.errors.add(:metadata, json_error)
    end
    @sections = HandbookSection.ordered
    flash.now[:error] = @article.errors.full_messages.join(", ")
    render :new, status: :unprocessable_entity
  end

  def edit
    @sections = HandbookSection.ordered
  end

  def update
    attrs, json_error = article_params
    if json_error
      @article.assign_attributes(attrs)
      @article.errors.add(:metadata, json_error)
      @sections = HandbookSection.ordered
      flash.now[:error] = @article.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
      return
    end

    if @article.update(attrs)
      set_flash_success("Article '#{@article.title}' updated.")
      redirect_to admin_handbook_articles_path(section_id: @article.handbook_section_id)
    else
      @sections = HandbookSection.ordered
      flash.now[:error] = @article.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    title = @article.title
    section_id = @article.handbook_section_id
    @article.destroy!
    set_flash_success("Article '#{title}' deleted.")
    redirect_to admin_handbook_articles_path(section_id: section_id)
  end

  private

  def set_article
    @article = HandbookArticle.find_by!(slug: params[:id])
  end

  # Returns [permitted_attrs, json_error_or_nil]. On invalid JSON, :metadata
  # is omitted so existing values are preserved on update, and a readable
  # error is surfaced.
  def article_params
    permitted = params.require(:handbook_article).permit(
      :handbook_section_id, :title, :slug, :kind, :difficulty,
      :summary, :body, :position, :published
    )

    json_source = params[:handbook_article][:metadata_json]
    if json_source.blank?
      permitted[:metadata] = {}
      return [permitted, nil]
    end

    parsed = JSON.parse(json_source)
    unless parsed.is_a?(Hash)
      return [permitted, "must be a JSON object (e.g. {\"search_tags\": [\"cred\", \"mining\"]})"]
    end

    permitted[:metadata] = parsed
    [permitted, nil]
  rescue JSON::ParserError => e
    [permitted, "is not valid JSON: #{e.message}"]
  end

  def next_position(section_id)
    return 0 if section_id.blank?
    (HandbookArticle.where(handbook_section_id: section_id).maximum(:position) || -1) + 1
  end
end
