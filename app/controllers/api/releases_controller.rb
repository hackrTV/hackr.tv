module Api
  class ReleasesController < ApplicationController
    # GET /api/releases
    def index
      @releases = Release.includes(:artist).order(Arel.sql("release_date DESC NULLS LAST"))

      render json: @releases.map { |release|
        {
          id: release.id,
          name: release.name,
          slug: release.slug,
          release_type: release.release_type,
          release_date: release.release_date,
          description: release.description,
          catalog_number: release.catalog_number,
          media_format: release.media_format,
          classification: release.classification,
          label: release.label,
          artist: {
            id: release.artist.id,
            name: release.artist.name,
            slug: release.artist.slug,
            genre: release.artist.genre
          },
          cover_url: release.cover_image.attached? ? url_for(release.cover_image) : nil,
          track_count: release.tracks.count,
          all_tracks_hidden: release.tracks.any? && release.tracks.visible_in_pulse_vault.none?
        }
      }
    end

    # GET /api/releases/:id
    def show
      @release = Release.find_by(slug: params[:id]) || Release.find(params[:id])

      tracks = @release.tracks.order(:track_number, :title)
      disc_length = tracks.sum { |t| parse_duration(t.duration) }

      render json: {
        id: @release.id,
        name: @release.name,
        slug: @release.slug,
        release_type: @release.release_type,
        release_date: @release.release_date,
        description: @release.description,
        catalog_number: @release.catalog_number,
        media_format: @release.media_format,
        classification: @release.classification,
        label: @release.label,
        credits: @release.credits,
        notes: @release.notes,
        streaming_links: @release.streaming_links,
        artist: {
          id: @release.artist.id,
          name: @release.artist.name,
          slug: @release.artist.slug,
          genre: @release.artist.genre
        },
        cover_url: @release.cover_image.attached? ? url_for(@release.cover_image) : nil,
        disc_length: format_duration(disc_length),
        tracks: tracks.map { |track|
          {
            id: track.id,
            title: track.title,
            slug: track.slug,
            track_number: track.track_number,
            duration: track.duration,
            streaming_links: track.streaming_links,
            audio_url: track.audio_file.attached? ? url_for(track.audio_file) : nil
          }
        }
      }
    end

    private

    def parse_duration(duration_str)
      return 0 if duration_str.blank?
      parts = duration_str.split(":").map(&:to_i)
      if parts.length == 2
        parts[0] * 60 + parts[1]
      elsif parts.length == 3
        parts[0] * 3600 + parts[1] * 60 + parts[2]
      else
        0
      end
    end

    def format_duration(total_seconds)
      minutes = total_seconds / 60
      seconds = total_seconds % 60
      "#{minutes}:#{seconds.to_s.rjust(2, "0")}"
    end
  end
end
