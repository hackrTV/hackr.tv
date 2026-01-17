module Api
  class EchoesController < ApplicationController
    include GridAuthentication

    before_action :require_login_api
    before_action :set_pulse

    # POST /api/pulses/:pulse_id/echo
    # Toggle echo - create if doesn't exist, destroy if it does
    def create
      existing_echo = @pulse.echoes.find_by(grid_hackr_id: current_hackr.id)

      if existing_echo
        # Echo already exists, remove it (un-echo)
        existing_echo.destroy

        render json: {
          success: true,
          echoed: false,
          echo_count: @pulse.reload.echo_count,
          message: "Echo removed"
        }
      else
        # Create new echo
        @echo = @pulse.echoes.build(grid_hackr: current_hackr)

        if @echo.save
          render json: {
            success: true,
            echoed: true,
            echo_count: @pulse.reload.echo_count,
            message: "Pulse echoed"
          }, status: :created
        else
          render json: {
            success: false,
            error: @echo.errors.full_messages.join(", ")
          }, status: :unprocessable_entity
        end
      end
    end

    # GET /api/pulses/:pulse_id/echoes
    # Get list of hackrs who echoed this pulse
    def index
      echoes = @pulse.echoes.includes(:grid_hackr).recent

      render json: {
        pulse_id: @pulse.id,
        echo_count: @pulse.echo_count,
        echoes: echoes.map do |echo|
          {
            id: echo.id,
            echoed_at: echo.echoed_at,
            hackr: {
              id: echo.grid_hackr.id,
              hackr_alias: echo.grid_hackr.hackr_alias,
              role: echo.grid_hackr.role
            }
          }
        end
      }
    end

    private

    def set_pulse
      @pulse = Pulse.find(params[:pulse_id])
    rescue ActiveRecord::RecordNotFound
      render json: {
        success: false,
        error: "Pulse not found"
      }, status: :not_found
    end
  end
end
