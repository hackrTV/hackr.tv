module PlayerHelper
  # Ported verbatim from utils/artistPaths.ts — artists with a profile
  # page. Unknown slugs return "" (context-menu item disabled).
  ARTIST_PROFILE_PATHS = {
    "xeraen" => "/xeraen/bio",
    "thecyberpulse" => "/thecyberpulse/bio",
    "system-rot" => "/system-rot",
    "wavelength-zero" => "/wavelength-zero",
    "voiceprint" => "/voiceprint",
    "temporal-blue-drift" => "/temporal-blue-drift",
    "injection-vector" => "/injection-vector",
    "cipher-protocol" => "/cipher-protocol",
    "blitzbeam" => "/blitzbeam",
    "apex-overdrive" => "/apex-overdrive",
    "ethereality" => "/ethereality",
    "neon-hearts" => "/neon-hearts",
    "offline" => "/offline",
    "heartbreak-havoc" => "/heartbreak-havoc"
  }.freeze

  def artist_profile_path_for(artist)
    ARTIST_PROFILE_PATHS[artist.slug.to_s] || ""
  end

  # Single source of truth for the player row contract (Phase 4): every
  # track table emits these on its playable rows, and track_list_controller
  # reads them back to build the queue. Keys mirror PlayerTrack in
  # player_controller.ts.
  def player_track_attrs(track)
    release = track.release
    cover_attached = release&.cover_image&.attached?

    {
      player_id: track.id,
      player_url: track.audio_file.attached? ? url_for(track.audio_file) : nil,
      player_title: track.title,
      player_artist: track.artist.name,
      player_cover: cover_attached ? url_for(release.cover_image) : "",
      player_cover_thumb: cover_attached ? url_for(release.cover_thumbnail) : "",
      player_cover_full: cover_attached ? url_for(release.cover_image) : ""
    }
  end
end
