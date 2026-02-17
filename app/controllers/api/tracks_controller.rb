module Api
  class TracksController < ApplicationController
    # GET /api/tracks
    # GET /api/artists/:artist_id/tracks
    def index
      if params[:artist_id]
        # Get tracks for specific artist
        artist = Artist.find_by(slug: params[:artist_id]) || Artist.find(params[:artist_id])
        @tracks = artist.tracks.visible_in_pulse_vault.includes(:release).order(Arel.sql("releases.release_date DESC NULLS LAST, tracks.track_number ASC")).joins(:release)
      else
        # Get all tracks with Pulse Vault ordering
        @tracks = Track.visible_in_pulse_vault.includes(:artist, :release).order(
          Arel.sql(<<-SQL.squish
            CASE artists.name
              WHEN 'The.CyberPul.se' THEN 0
              WHEN 'XERAEN' THEN 1
              WHEN 'Wavelength Zero' THEN 2
              WHEN 'Voiceprint' THEN 3
              WHEN 'Temporal Blue Drift' THEN 4
              WHEN 'heartbreak_havoc.sh' THEN 5
              WHEN 'System Rot' THEN 6
              WHEN 'Apex Overdrive' THEN 7
              WHEN 'Cipher Protocol' THEN 8
              WHEN 'Neon Hearts' THEN 9
              ELSE 10
            END,
            CASE WHEN artists.name IN ('The.CyberPul.se', 'XERAEN', 'Wavelength Zero', 'Voiceprint', 'Temporal Blue Drift', 'heartbreak_havoc.sh', 'System Rot', 'Apex Overdrive', 'Cipher Protocol', 'Neon Hearts') THEN '' ELSE artists.name END,
            releases.release_date DESC,
            tracks.track_number ASC
          SQL
                  )
        ).joins(:artist, :release)
      end

      render json: @tracks.map { |track|
        {
          id: track.id,
          title: track.title,
          slug: track.slug,
          track_number: track.track_number,
          duration: track.duration,
          featured: track.featured,
          artist: {
            id: track.artist.id,
            name: track.artist.name,
            slug: track.artist.slug,
            genre: track.artist.genre
          },
          release: if track.release
                     {
                       id: track.release.id,
                       name: track.release.name,
                       slug: track.release.slug,
                       release_date: track.release.release_date,
                       cover_url: track.release.cover_image.attached? ? url_for(track.release.cover_image) : nil
                     }
                   end,
          audio_url: track.audio_file.attached? ? url_for(track.audio_file) : nil
        }
      }
    end

    # GET /api/tracks/:id
    def show
      @track = Track.includes(:artist, :release, :hackr_streams).find_by(slug: params[:id])
      @track ||= Track.includes(:artist, :release, :hackr_streams).find_by(id: params[:id]) if params[:id].to_i.to_s == params[:id]

      if @track.nil?
        render json: {error: "Track not found"}, status: :not_found
        return
      end

      render json: {
        id: @track.id,
        title: @track.title,
        slug: @track.slug,
        track_number: @track.track_number,
        duration: @track.duration,
        featured: @track.featured,
        release_date: @track.release_date,
        lyrics: @track.lyrics,
        streaming_links: @track.streaming_links,
        videos: @track.videos,
        artist: {
          id: @track.artist.id,
          name: @track.artist.name,
          slug: @track.artist.slug,
          genre: @track.artist.genre
        },
        release: if @track.release
                   {
                     id: @track.release.id,
                     name: @track.release.name,
                     slug: @track.release.slug,
                     release_type: @track.release.release_type,
                     release_date: @track.release.release_date,
                     description: @track.release.description,
                     cover_url: @track.release.cover_image.attached? ? url_for(@track.release.cover_image) : nil
                   }
                 end,
        audio_url: @track.audio_file.attached? ? url_for(@track.audio_file) : nil,
        vidz: @track.hackr_streams.map { |v| {id: v.id, title: v.title, vod_url: v.vod_url} }
      }
    end
  end
end
