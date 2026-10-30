# The /root music screens — artists, releases and tracks as console
# screens on the family in console.css (+ root_console.css; 2026-10-30):
# the destination rows every screen ends on, the "> " prompt's hint, the
# public-side links, the ledgers' readouts and the hidden DELETE forms the
# ghost buttons submit. Admin views only (the admin layout).
module Admin::MusicConsoleHelper
  # [TAG, route helper, name, description] — the tag doubles as the
  # prompt command (the terminal controller reads a[data-command]).
  ROOT_DESTINATIONS = [
    ["ARTISTS", :admin_artists_path, "Artists", "Every act on record — bands, OSTs, voiceovers"],
    ["RELEASES", :admin_releases_path, "Releases", "Albums, EPs and singles across the catalog"],
    ["TRACKS", :admin_tracks_path, "Tracks", "Every transmission — audio, lyrics, frequencies"],
    ["RADIO", :admin_radio_stations_path, "Radio", "The hackr.fm stations and their playlists"],
    ["ROOT", :admin_root_path, "Dashboard", "Back to the /root overview"]
  ].freeze

  # The release types the TYPE select offers (the catalog's words).
  RELEASE_TYPES = %w[single ep album lp compilation mixtape].freeze

  # The streaming platforms a release / track carries, in the catalog's
  # display order (the // FREQUENCIES // rows).
  def root_streaming_platforms
    ArtistCatalogHelper::STREAMING_PLATFORM_ORDER
  end

  def root_destinations(except: nil)
    ROOT_DESTINATIONS.reject { |tag, *| tag == except }
      .map { |tag, helper, name, desc| [tag, public_send(helper), name, desc] }
  end

  # "type a track number (01–99) or type a tag (new releases …) · enter ·
  # ? help". except: the screen's own tag; numbers: its numbered rows (a
  # range past eight); extra: commands the bar adds (new).
  def root_prompt_hint(except: nil, numbers: [], noun: "a number", extra: [])
    tags = extra + root_destinations(except: except).map { |t, *| t.downcase }
    parts = []
    if numbers.any?
      shown = (numbers.size > 8) ? "#{numbers.first}–#{numbers.last}" : numbers.join(" ")
      parts << safe_join(["type #{noun} ", tag.span("(#{shown})", class: "console-dim"), " or "])
    end
    parts << "type a tag " << tag.span("(#{tags.join(" ")})", class: "console-dim") << " · enter · ? help"
    safe_join(parts)
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

  # The ledgers' [NN].
  def root_num(index)
    format("%02d", index + 1)
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

  # The inline error after a field.
  def root_errors(record, attribute)
    messages = record.errors[attribute]
    return if messages.empty?
    tag.span(messages.join(", "), class: "rc-err")
  end

  # A hidden DELETE form a ghost button elsewhere on the screen submits
  # (<button form="<id>">): the record forms can't nest a button_to, and
  # the admin layout's confirm handler reads the form's data-confirm.
  def root_delete_form(id, url, confirm: nil, data: {})
    form_with(url: url, method: :delete, id: id, local: true,
      data: data.merge(confirm: confirm).compact) { "" }
  end

  # The search haystack a tracks-ledger row filters on.
  def root_track_search(track)
    [track.title, track.slug, track.artist.name, track.release.name, track.release.slug].join(" ").downcase
  end
end
