module Api
  module Admin
    class UplinkController < BaseController
      before_action :resolve_hackr!
      before_action :set_channel

      # POST /api/admin/uplink/send_packet
      def send_packet
        # Moderation bypass is role-dependent:
        # Admin hackrs bypass squelch/blackout/slow-mode
        # Non-admin hackrs are still subject to moderation even through admin API
        unless @acting_hackr.admin?
          if UserPunishment.blackouted?(@acting_hackr)
            return render json: {
              success: false,
              error: "This hackr has been blackouted from chat."
            }, status: :forbidden
          end

          if UserPunishment.squelched?(@acting_hackr)
            return render json: {
              success: false,
              error: "This hackr has been squelched."
            }, status: :forbidden
          end

          # Slow mode enforcement for non-admin hackrs
          if @channel.slow_mode_seconds > 0
            last_message = @channel.chat_messages
              .where(grid_hackr: @acting_hackr)
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
        end

        # Get current livestream if channel requires it
        hackr_stream = @channel.requires_livestream ? HackrStream.current_live : nil

        packet = @channel.chat_messages.build(
          grid_hackr: @acting_hackr,
          hackr_stream: hackr_stream,
          content: params[:content]
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
          hackr_stream_id: packet.hackr_stream_id
        }
      end
    end
  end
end
