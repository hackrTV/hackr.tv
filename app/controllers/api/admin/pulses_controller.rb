module Api
  module Admin
    class PulsesController < BaseController
      # POST /api/admin/pulses
      def create
        pulse = @current_admin_hackr.pulses.build(
          content: params[:content],
          pulsed_at: Time.current
        )

        if pulse.save
          render json: {
            success: true,
            message: "Pulse broadcast",
            pulse: pulse_json(pulse)
          }, status: :created
        else
          error_message = pulse.errors[:content].first || pulse.errors.full_messages.join(", ")
          render json: {success: false, error: error_message}, status: :unprocessable_entity
        end
      end

      # POST /api/admin/pulses/:pulse_id/echo
      def echo
        pulse = Pulse.find_by(id: params[:pulse_id])
        unless pulse
          return render json: {success: false, error: "Pulse not found"}, status: :not_found
        end

        existing_echo = pulse.echoes.find_by(grid_hackr_id: @current_admin_hackr.id)

        if existing_echo
          existing_echo.destroy
          render json: {
            success: true,
            echoed: false,
            echo_count: pulse.reload.echo_count,
            message: "Echo removed"
          }
        else
          new_echo = pulse.echoes.build(grid_hackr: @current_admin_hackr)
          if new_echo.save
            render json: {
              success: true,
              echoed: true,
              echo_count: pulse.reload.echo_count,
              message: "Pulse echoed"
            }, status: :created
          else
            render json: {
              success: false,
              error: new_echo.errors.full_messages.join(", ")
            }, status: :unprocessable_entity
          end
        end
      end

      # POST /api/admin/pulses/splice
      def splice
        parent = Pulse.find_by(id: params[:parent_pulse_id])
        unless parent
          return render json: {success: false, error: "Parent pulse not found"}, status: :not_found
        end

        pulse = @current_admin_hackr.pulses.build(
          content: params[:content],
          parent_pulse_id: parent.id,
          pulsed_at: Time.current
        )

        if pulse.save
          render json: {
            success: true,
            message: "Splice broadcast",
            pulse: pulse_json(pulse)
          }, status: :created
        else
          error_message = pulse.errors[:content].first ||
            pulse.errors[:parent_pulse_id].first ||
            pulse.errors.full_messages.join(", ")
          render json: {success: false, error: error_message}, status: :unprocessable_entity
        end
      end

      private

      def pulse_json(pulse)
        {
          id: pulse.id,
          content: pulse.content,
          pulsed_at: pulse.pulsed_at&.iso8601,
          echo_count: pulse.echo_count,
          splice_count: pulse.splices.count,
          signal_dropped: pulse.signal_dropped,
          parent_pulse_id: pulse.parent_pulse_id,
          thread_root_id: pulse.thread_root_id,
          is_splice: pulse.is_splice?,
          grid_hackr: {
            id: pulse.grid_hackr.id,
            hackr_alias: pulse.grid_hackr.hackr_alias
          },
          created_at: pulse.created_at.iso8601,
          updated_at: pulse.updated_at.iso8601
        }
      end
    end
  end
end
