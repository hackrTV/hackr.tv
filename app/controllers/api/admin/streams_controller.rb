module Api
  module Admin
    class StreamsController < BaseController
      # GET /api/admin/streams/status
      def status
        stream = HackrStream.current_live

        if stream
          render json: {
            success: true,
            is_live: true,
            stream: {
              id: stream.id,
              title: stream.title,
              live_url: stream.live_url,
              started_at: stream.started_at&.iso8601,
              artist: {
                id: stream.artist.id,
                name: stream.artist.name,
                slug: stream.artist.slug
              }
            }
          }
        else
          render json: {success: true, is_live: false}
        end
      end

      # POST /api/admin/streams/go_live
      def go_live
        artist = Artist.find_by(slug: params[:artist_slug])
        unless artist
          return render json: {success: false, error: "Artist not found"}, status: :not_found
        end

        url = params[:url]
        title = params[:title]

        unless url.present?
          return render json: {success: false, error: "URL is required"}, status: :unprocessable_entity
        end

        # End all currently live streams
        HackrStream.live.find_each(&:end_stream!)

        # Create a new stream (cannot_restart_stream validation prevents reuse)
        stream = HackrStream.create!(artist: artist)
        stream.go_live!(url, title)

        render json: {
          success: true,
          message: "Stream is now live",
          stream: {
            id: stream.id,
            title: stream.title,
            live_url: stream.live_url,
            started_at: stream.started_at&.iso8601,
            artist: {
              id: artist.id,
              name: artist.name,
              slug: artist.slug
            }
          }
        }, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: {success: false, error: e.message}, status: :unprocessable_entity
      end

      # POST /api/admin/streams/end_stream
      def end_stream
        artist = Artist.find_by(slug: params[:artist_slug])
        unless artist
          return render json: {success: false, error: "Artist not found"}, status: :not_found
        end

        stream = artist.hackr_streams.live.first
        unless stream
          return render json: {success: false, error: "No live stream found for this artist"}, status: :not_found
        end

        stream.end_stream!

        render json: {
          success: true,
          message: "Stream ended",
          stream: {
            id: stream.id,
            title: stream.title,
            ended_at: stream.ended_at&.iso8601
          }
        }
      end
    end
  end
end
