module Api
  class ReleasesController < ApplicationController
    # GET /api/releases
    def index
      @releases = Release.includes(:artist).where(coming_soon: false).order(Arel.sql("release_date DESC NULLS LAST"))

      render json: @releases.reject { |r| r.tracks.any? && r.tracks.where(show_in_pulse_vault: true).none? }.map { |release|
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
          cover_urls: cover_urls_for(release),
          track_count: release.tracks.count
        }
      }
    end

    # GET /api/releases/latest
    def latest
      @releases = Release.includes(:artist, cover_image_attachment: :blob)
        .where(label: "hackr.fm", coming_soon: false)
        .where.associated(:cover_image_attachment)
        .order(Arel.sql("release_date DESC NULLS LAST"))

      visible = @releases.reject { |r| r.tracks.any? && r.tracks.where(show_in_pulse_vault: true).none? }.first(3)

      render json: visible.map { |release|
        {
          id: release.id,
          name: release.name,
          slug: release.slug,
          release_type: release.release_type,
          release_date: release.release_date,
          label: release.label,
          artist: {
            id: release.artist.id,
            name: release.artist.name,
            slug: release.artist.slug
          },
          cover_url: url_for(release.cover_image),
          cover_urls: cover_urls_for(release),
          track_count: release.tracks.count
        }
      }
    end

    # GET /api/releases/:id
    def show
      @release = Release.find_by(slug: params[:id]) || Release.find(params[:id])

      if !@release.coming_soon && @release.tracks.any? && @release.tracks.where(show_in_pulse_vault: true).none?
        return head :not_found
      end

      tracks = @release.tracks.includes(:hackr_streams).order(:track_number, :title)
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
        coming_soon: @release.coming_soon,
        artist: {
          id: @release.artist.id,
          name: @release.artist.name,
          slug: @release.artist.slug,
          genre: @release.artist.genre
        },
        cover_url: @release.cover_image.attached? ? url_for(@release.cover_image) : nil,
        cover_urls: cover_urls_for(@release),
        disc_length: format_duration(disc_length),
        tracks: tracks.map { |track|
          {
            id: track.id,
            title: track.title,
            slug: track.slug,
            track_number: track.track_number,
            duration: track.duration,
            streaming_links: track.streaming_links,
            audio_url: track.audio_file.attached? ? url_for(track.audio_file) : nil,
            vidz: track.hackr_streams.map { |v| {id: v.id, title: v.title} }
          }
        }
      }
    end

    # GET /api/releases/coming_soon
    def coming_soon
      @releases = Release.includes(:artist, cover_image_attachment: :blob)
        .where(coming_soon: true)
        .order(Arel.sql("release_date ASC NULLS LAST"))

      render json: @releases.map { |release|
        {
          id: release.id,
          name: release.name,
          slug: release.slug,
          release_type: release.release_type,
          release_date: release.release_date,
          label: release.label,
          artist: {
            id: release.artist.id,
            name: release.artist.name,
            slug: release.artist.slug
          },
          cover_url: release.cover_image.attached? ? url_for(release.cover_image) : nil,
          cover_urls: cover_urls_for(release),
          track_count: release.tracks.count
        }
      }
    end

    # POST /api/releases/:id/viewed
    def viewed
      return head :no_content unless current_hackr

      release = Release.find_by(slug: params[:id]) || Release.find_by(id: params[:id])
      return head :not_found unless release
      return head :unprocessable_entity if release.coming_soon

      HackrPageView.record!(current_hackr, "release", release.id)
      Grid::AchievementChecker.new(current_hackr).check("releases_viewed_all")

      head :no_content
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
