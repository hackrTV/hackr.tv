module Api
  module Uplink
    class ChannelsController < ApplicationController
      include GridAuthentication

      # GET /api/uplink/channels
      def index
        channels = ChatChannel.active.map do |channel|
          channel_json(channel)
        end

        render json: {
          channels: channels,
          current_hackr: current_hackr_json
        }
      end

      # GET /api/uplink/channels/:slug
      def show
        channel = ChatChannel.find_by(slug: params[:slug])

        unless channel
          return render json: {
            success: false,
            error: "Channel not found"
          }, status: :not_found
        end

        render json: {
          channel: channel_json(channel),
          current_hackr: current_hackr_json
        }
      end

      private

      def channel_json(channel)
        {
          slug: channel.slug,
          name: channel.name,
          description: channel.description,
          is_active: channel.is_active,
          requires_livestream: channel.requires_livestream,
          currently_available: channel.currently_available?,
          accessible: logged_in? ? channel.accessible_by?(current_hackr) : false,
          slow_mode_seconds: channel.slow_mode_seconds,
          minimum_role: channel.minimum_role
        }
      end

      def current_hackr_json
        return nil unless logged_in?

        {
          id: current_hackr.id,
          hackr_alias: current_hackr.hackr_alias,
          role: current_hackr.role,
          is_squelched: UserPunishment.squelched?(current_hackr),
          is_blackedout: UserPunishment.blackedout?(current_hackr)
        }
      end
    end
  end
end
