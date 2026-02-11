module Api
  module Uplink
    class PacketsController < ApplicationController
      include GridAuthentication

      before_action :set_channel, only: %i[index create]
      before_action :require_login_api, only: %i[create destroy]
      before_action :set_packet, only: [:destroy]
      before_action :require_operator_or_owner, only: [:destroy]

      # GET /api/uplink/channels/:channel_slug/packets
      def index
        packets = @channel.chat_messages
          .active
          .recent
          .limit(params[:limit] || 50)
          .includes(:grid_hackr)

        render json: {
          packets: packets.reverse.map { |p| packet_json(p) },
          channel: @channel.slug,
          current_hackr: current_hackr_json
        }
      end

      # POST /api/uplink/channels/:channel_slug/packets
      def create
        # Check if user is blackouted
        if UserPunishment.blackouted?(current_hackr)
          return render json: {
            success: false,
            error: "You have been blackedout from Uplink."
          }, status: :forbidden
        end

        # Check if user is squelched
        if UserPunishment.squelched?(current_hackr)
          return render json: {
            success: false,
            error: "You have been squelched. Please wait for your squelch to expire."
          }, status: :forbidden
        end

        # Check channel accessibility
        unless @channel.accessible_by?(current_hackr)
          return render json: {
            success: false,
            error: "You cannot access this channel."
          }, status: :forbidden
        end

        # Check slow mode
        if @channel.slow_mode_seconds > 0
          last_message = @channel.chat_messages
            .where(grid_hackr: current_hackr)
            .order(created_at: :desc)
            .first

          if last_message && last_message.created_at > @channel.slow_mode_seconds.seconds.ago
            wait_time = (@channel.slow_mode_seconds - (Time.current - last_message.created_at)).ceil
            return render json: {
              success: false,
              error: "Slow mode active. Please wait #{wait_time} seconds.",
              wait_seconds: wait_time
            }, status: :too_many_requests
          end
        end

        # Get current livestream if channel requires it
        hackr_stream = @channel.requires_livestream ? HackrStream.current_live : nil

        @packet = @channel.chat_messages.build(
          grid_hackr: current_hackr,
          hackr_stream: hackr_stream,
          content: packet_params[:content]
        )

        if @packet.save
          render json: {
            success: true,
            message: "Packet transmitted",
            packet: packet_json(@packet)
          }, status: :created
        else
          error_message = @packet.errors[:content].first || @packet.errors.full_messages.join(", ")
          render json: {
            success: false,
            error: error_message
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/uplink/packets/:id
      def destroy
        if @packet.drop!
          ModerationLog.log_action(
            actor: current_hackr,
            action: "drop_packet",
            chat_message: @packet,
            target: @packet.grid_hackr
          )

          render json: {
            success: true,
            message: "Packet dropped"
          }
        else
          render json: {
            success: false,
            error: "Failed to drop packet"
          }, status: :unprocessable_entity
        end
      end

      private

      def set_channel
        @channel = ChatChannel.find_by(slug: params[:channel_slug])

        unless @channel
          render json: {
            success: false,
            error: "Channel not found"
          }, status: :not_found
        end
      end

      def set_packet
        @packet = ChatMessage.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          success: false,
          error: "Packet not found"
        }, status: :not_found
      end

      def require_operator_or_owner
        return if current_hackr.at_least_operator?
        return if @packet.grid_hackr_id == current_hackr.id

        render json: {
          success: false,
          error: "You are not authorized to drop this packet"
        }, status: :forbidden
      end

      def packet_params
        params.require(:packet).permit(:content)
      end

      def packet_json(packet)
        {
          id: packet.id,
          content: packet.content,
          created_at: packet.created_at.iso8601,
          dropped: packet.dropped,
          grid_hackr: {
            id: packet.grid_hackr_id,
            hackr_alias: packet.grid_hackr&.hackr_alias,
            role: packet.grid_hackr&.role
          },
          hackr_stream_id: packet.hackr_stream_id
        }
      end

      def current_hackr_json
        return nil unless logged_in?

        {
          id: current_hackr.id,
          hackr_alias: current_hackr.hackr_alias,
          role: current_hackr.role
        }
      end
    end
  end
end
