# frozen_string_literal: true

module Api
  module Admin
    class OverlayController < BaseController
      # POST /api/admin/overlay/ticker_feed
      #
      # Push content to a dynamic ticker. Used by Synthia and other
      # external services to feed real-time text into overlay tickers.
      #
      # Params:
      #   slug: (required) Ticker slug to update
      #   content: (required) Text content to display
      def ticker_feed
        slug = params[:slug].to_s.strip
        content = params[:content].to_s.strip

        if slug.blank?
          return render json: {success: false, error: "Missing required parameter: slug"}, status: :unprocessable_entity
        end

        if content.blank?
          return render json: {success: false, error: "Missing required parameter: content"}, status: :unprocessable_entity
        end

        ticker = OverlayTicker.find_by(slug: slug)
        unless ticker
          return render json: {success: false, error: "Ticker not found: #{slug}"}, status: :not_found
        end

        unless ticker.dynamic? && ticker.feed_source == "api"
          return render json: {success: false, error: "Ticker '#{slug}' is not configured for API feed"}, status: :unprocessable_entity
        end

        ticker.update!(content: content.truncate(1024))
        ticker.broadcast_update!

        render json: {
          success: true,
          ticker: {
            slug: ticker.slug,
            content: ticker.content,
            content_type: ticker.content_type,
            feed_source: ticker.feed_source
          }
        }
      end
    end
  end
end
