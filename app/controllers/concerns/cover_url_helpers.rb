module CoverUrlHelpers
  private

  def cover_urls_for(release)
    return nil unless release&.cover_image&.attached?
    {
      thumbnail: url_for(release.cover_thumbnail),
      standard: url_for(release.cover_standard),
      full: url_for(release.cover_image)
    }
  end
end
