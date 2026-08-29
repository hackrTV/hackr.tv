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
        # Blackout / squelch / role access / slow mode — shared with the
        # Hotwire form flow (Phase 5) via the gatekeeper.
        gate = ::Uplink::PacketGatekeeper.check(current_hackr, @channel)
        unless gate.ok?
          payload = {success: false, error: gate.error}
          payload[:wait_seconds] = gate.wait_seconds if gate.wait_seconds
          return render json: payload, status: gate.status
        end

        # Get current livestream if channel requires it
        hackr_stream = @channel.requires_livestream ? HackrStream.current_live : nil

        @packet = @channel.chat_messages.build(
          grid_hackr: current_hackr,
          hackr_stream: hackr_stream,
          content: packet_params[:content]
        )

        if @packet.save
          # "Packet" is the in-world user-facing term for an Uplink
          # message — aesthetic naming to preserve the Grid's fourth
          # wall. Underlying model is `ChatMessage` (see @packet
          # assignment above: `@channel.chat_messages.build(...)`).
          # The `uplink_packets_count` achievement trigger counts
          # `chat_messages` rows — same table, same rows, cosmetic
          # alias only.
          Grid::AchievementChecker.new(current_hackr).check("uplink_packets_count")
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
          hackr_stream_id: packet.hackr_stream_id,
          source: packet.source
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
