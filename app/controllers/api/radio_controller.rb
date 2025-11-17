module Api
  class RadioController < ApplicationController
    # GET /api/radio_stations
    def index
      stations = RadioStation.ordered.includes(playlists: [:tracks, :grid_hackr])

      render json: stations.map { |station|
        {
          id: station.id,
          name: station.name,
          slug: station.slug,
          description: station.description,
          genre: station.genre,
          color: station.color,
          stream_url: station.stream_url,
          position: station.position,
          playlists: station.radio_station_playlists.order(position: :asc).map { |rsp|
            playlist = rsp.playlist
            {
              id: playlist.id,
              name: playlist.name,
              description: playlist.description,
              track_count: playlist.track_count,
              is_public: playlist.is_public,
              share_token: playlist.share_token
            }
          }
        }
      }
    end

    # GET /api/radio_stations/:id/playlists
    # Returns all playlists assigned to a radio station with their tracks
    # This is public - anyone can fetch playlists assigned to a station
    def station_playlists
      station = RadioStation.find(params[:id])
      playlists = station.radio_station_playlists
        .includes(playlist: {playlist_tracks: {track: [:artist, :album]}})
        .order(position: :asc)

      render json: playlists.map { |rsp|
        playlist = rsp.playlist
        {
          id: playlist.id,
          name: playlist.name,
          description: playlist.description,
          is_public: playlist.is_public,
          track_count: playlist.track_count,
          tracks: playlist.playlist_tracks.order(position: :asc).map { |playlist_track|
            track = playlist_track.track
            {
              id: playlist_track.id,
              track_id: track.id,
              title: track.title,
              slug: track.slug,
              track_number: track.track_number,
              duration: track.duration,
              position: playlist_track.position,
              artist: {
                id: track.artist.id,
                name: track.artist.name,
                slug: track.artist.slug
              },
              album: if track.album
                       {
                         id: track.album.id,
                         name: track.album.name,
                         slug: track.album.slug,
                         cover_url: track.album.cover_image.attached? ? url_for(track.album.cover_image) : nil
                       }
                     end,
              audio_url: track.audio_file.attached? ? url_for(track.audio_file) : nil
            }
          }
        }
      }
    rescue ActiveRecord::RecordNotFound
      render json: {error: "Radio station not found"}, status: :not_found
    end
  end
end
