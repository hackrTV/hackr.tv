# The /root release and track forms' // FREQUENCIES // rows post the
# streaming links as streaming_links[<platform>] = url. A blank row means
# no link on that platform, an all-blank set means nil — a release with
# nil links aggregates its tracks' on the public page (console_release /
# release.html.erb), so "no links of its own" must stay nil, not {}.
module Admin::MusicParams
  extend ActiveSupport::Concern

  STREAMING_PLATFORMS = ArtistCatalogHelper::STREAMING_PLATFORM_ORDER

  private

  def normalize_streaming_links!(attrs)
    return attrs unless attrs.key?(:streaming_links)
    links = attrs[:streaming_links].to_h
      .transform_values { |url| url.to_s.strip }
      .reject { |_platform, url| url.blank? }
    attrs[:streaming_links] = links.presence
    attrs
  end
end
