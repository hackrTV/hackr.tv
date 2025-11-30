class OverlayNowPlaying < ApplicationRecord
  self.table_name = "overlay_now_playing"

  # Associations
  belongs_to :track, optional: true

  # Singleton pattern - only one record should exist
  def self.current
    first_or_create!
  end

  def self.set_track!(track, paused: false)
    current.update!(
      track: track,
      custom_title: nil,
      custom_artist: nil,
      started_at: Time.current,
      paused: paused
    )
    broadcast_change!
  end

  def self.set_custom!(title:, artist: nil)
    current.update!(
      track: nil,
      custom_title: title,
      custom_artist: artist,
      started_at: Time.current,
      paused: false
    )
    broadcast_change!
  end

  def self.set_paused!(paused)
    current.update!(paused: paused)
    broadcast_change!
  end

  def self.clear!
    current.update!(
      track: nil,
      custom_title: nil,
      custom_artist: nil,
      started_at: nil,
      paused: false
    )
    broadcast_change!
  end

  # Display helpers
  def display_title
    custom_title.presence || track&.title || "Nothing Playing"
  end

  def display_artist
    custom_artist.presence || track&.artist&.name || ""
  end

  def display_album
    track&.album&.name || ""
  end

  def album_cover_url
    return nil unless track&.album&.cover_image&.attached?

    Rails.application.routes.url_helpers.rails_blob_url(
      track.album.cover_image,
      only_path: true
    )
  end

  def playing?
    track.present? || custom_title.present?
  end

  # Broadcast to overlay channel
  def self.broadcast_change!
    now_playing = current
    ActionCable.server.broadcast("overlay_updates", {
      type: "now_playing_changed",
      data: {
        track_id: now_playing.track_id,
        title: now_playing.display_title,
        artist: now_playing.display_artist,
        album: now_playing.display_album,
        album_cover: now_playing.album_cover_url,
        started_at: now_playing.started_at&.iso8601,
        is_live: now_playing.is_live,
        playing: now_playing.playing?,
        paused: now_playing.paused
      }
    })
  end
end
