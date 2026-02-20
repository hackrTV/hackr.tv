module Api
  module Admin
    class UplinkController < BaseController
      before_action :set_channel

      # POST /api/admin/uplink/send_packet
      def send_packet
        # Admin auth is enforced by BaseController — admins bypass all moderation
        hackr_stream = @channel.requires_livestream ? HackrStream.current_live : nil

        packet = @channel.chat_messages.build(
          grid_hackr: @current_admin_hackr,
          hackr_stream: hackr_stream,
          content: params[:content],
          source: params[:source]
        )

        if packet.save
          render json: {
            success: true,
            message: "Packet transmitted",
            packet: packet_json(packet)
          }, status: :created
        else
          error_message = packet.errors[:content].first || packet.errors.full_messages.join(", ")
          render json: {success: false, error: error_message}, status: :unprocessable_entity
        end
      end

      private

      def set_channel
        @channel = ChatChannel.find_by(slug: params[:channel_slug])
        unless @channel
          render json: {success: false, error: "Channel not found"}, status: :not_found
        end
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
    end
  end
end
