# The /root music screens' own readouts — artists, releases and tracks
# as console screens (2026-10-30): the public-side links, the release /
# audio / cover states and the tracks ledger's haystack. The screen
# idiom itself (destinations, prompt hint, [NN], errors, delete forms)
# is Admin::ConsoleHelper. Admin views only (the admin layout).
module Admin::MusicConsoleHelper
  # The release types the TYPE select offers (the catalog's words).
  RELEASE_TYPES = %w[single ep album lp compilation mixtape].freeze

  # The streaming platforms a release / track carries, in the catalog's
  # display order (the // FREQUENCIES // rows).
  def root_streaming_platforms
    ArtistCatalogHelper::STREAMING_PLATFORM_ORDER
  end

  # The public side of a record, when its artist is routed (the catalog
  # routes are per-slug — config/routes.rb artist_slugs): nil for an
  # artist without public pages, so the bar shows no [>] PUBLIC.
  def root_public_path(path)
    route = Rails.application.routes.recognize_path(path)
    (route[:controller] == "artist_catalog") ? path : nil
  rescue ActionController::RoutingError
    nil
  end

  def root_public_catalog_path(artist)
    root_public_path("/#{artist.slug}/releases")
  end

  def root_public_release_path(release)
    root_public_path("/#{release.artist.slug}/releases/#{release.slug_in_database}")
  end

  def root_public_track_path(track)
    root_public_path("/#{track.artist.slug}/trackz/#{track.slug_in_database}")
  end

  # [word, class] for a release's state cell: INCOMING (coming soon),
  # HIDDEN (every track kept out of the vault — the public catalog skips
  # it), LIVE.
  def root_release_status(release)
    if release.coming_soon
      ["INCOMING", "rc-hot"]
    elsif release.tracks.any? && release.tracks.none?(&:show_in_pulse_vault)
      ["HIDDEN", "rc-off"]
    else
      ["LIVE", "rc-on"]
    end
  end

  # A cover that can be rendered: attached AND persisted — after a
  # rejected upload the attachment holds an unpersisted blob and url_for
  # raises (gotchas, the emotes find).
  def root_cover_ready?(release)
    release.cover_image.attached? && release.cover_image.blob.persisted?
  end

  def root_audio_ready?(track)
    track.audio_file.attached? && track.audio_file.blob.persisted?
  end

  # The search haystack a tracks-ledger row filters on.
  def root_track_search(track)
    [track.title, track.slug, track.artist.name, track.release.name, track.release.slug].join(" ").downcase
  end
end
