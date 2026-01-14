module Api
  class PulsesController < ApplicationController
    include GridAuthentication

    before_action :require_login_api, only: %i[create destroy signal_drop]
    before_action :set_pulse, only: %i[show destroy signal_drop]
    before_action :authorize_pulse_owner, only: [:destroy]
    before_action :require_admin, only: [:signal_drop]

    # GET /api/pulses
    # Params: page (default 1), per_page (default 50), filter (all/active/dropped), hackr (username), parent_pulse_id (for replies), echoed_by (username)
    def index
      pulses = Pulse.includes(:grid_hackr, :parent_pulse, :echoes)

      # Filter by parent_pulse_id if specified (for fetching replies)
      if params[:parent_pulse_id].present?
        pulses = pulses.where(parent_pulse_id: params[:parent_pulse_id])
      elsif params[:include_splices] != "true"
        # Default to root pulses only (no splices) to avoid duplication in timeline
        # Use include_splices=true to show all pulses (e.g., on user profile pages)
        pulses = pulses.roots
      end

      # Filter by hackr if specified (case-insensitive)
      if params[:hackr].present?
        hackr = GridHackr.where("LOWER(hackr_alias) = ?", params[:hackr].downcase).first
        return render json: {pulses: [], meta: {total: 0, page: 1, per_page: 50}} unless hackr

        pulses = pulses.where(grid_hackr_id: hackr.id)

      end

      # Filter by echoed_by - pulses that a specific user has echoed
      if params[:echoed_by].present?
        echoing_hackr = GridHackr.where("LOWER(hackr_alias) = ?", params[:echoed_by].downcase).first
        return render json: {pulses: [], meta: {total: 0, page: 1, per_page: 50}} unless echoing_hackr

        pulses = pulses.joins(:echoes).where(echoes: {grid_hackr_id: echoing_hackr.id})

      end

      # Filter by status
      pulses = case params[:filter]
      when "dropped"
        pulses.dropped
      when "active"
        pulses.active
      else
        pulses.active # Default to active only
      end

      # Pagination
      page = [params[:page].to_i, 1].max
      per_page = [params[:per_page].to_i, 50].max
      per_page = [per_page, 100].min # Cap at 100

      total = pulses.count
      pulses = pulses.timeline.limit(per_page).offset((page - 1) * per_page)

      render json: {
        pulses: pulses.map { |pulse| pulse_json(pulse) },
        current_hackr: if logged_in?
                         {id: current_hackr.id, hackr_alias: current_hackr.hackr_alias,
                          role: current_hackr.role}
                       end,
        meta: {
          total: total,
          page: page,
          per_page: per_page,
          total_pages: (total.to_f / per_page).ceil
        }
      }
    end

    # GET /api/pulses/:id
    def show
      # Include full thread
      thread = @pulse.thread_pulses.includes(:grid_hackr, :echoes)

      render json: {
        pulse: pulse_json(@pulse),
        thread: thread.map { |p| pulse_json(p) }
      }
    end

    # POST /api/pulses
    # Params: content (required), parent_pulse_id (optional for splicing)
    def create
      @pulse = current_hackr.pulses.build(pulse_params)

      if @pulse.save
        render json: {
          success: true,
          message: "Pulse broadcast successfully",
          pulse: pulse_json(@pulse)
        }, status: :created
      else
        # Use content errors directly to avoid "Content" prefix on profanity errors
        error_message = @pulse.errors[:content].first || @pulse.errors.full_messages.join(", ")
        render json: {
          success: false,
          error: error_message
        }, status: :unprocessable_entity
      end
    end

    # DELETE /api/pulses/:id
    def destroy
      @pulse.destroy

      # Broadcast deletion
      ActionCable.server.broadcast("pulse_wire", {
        type: "pulse_deleted",
        pulse_id: @pulse.id
      })

      render json: {
        success: true,
        message: "Pulse deleted successfully"
      }
    end

    # POST /api/pulses/:id/signal_drop
    def signal_drop
      if @pulse.signal_drop!
        # Broadcast signal drop
        ActionCable.server.broadcast("pulse_wire", {
          type: "pulse_dropped",
          pulse_id: @pulse.id
        })

        render json: {
          success: true,
          message: "Pulse signal-dropped by GovCorp",
          pulse: pulse_json(@pulse)
        }
      else
        render json: {
          success: false,
          error: @pulse.errors.full_messages.join(", ")
        }, status: :unprocessable_entity
      end
    end

    private

    def set_pulse
      @pulse = Pulse.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: {
        success: false,
        error: "Pulse not found"
      }, status: :not_found
    end

    def authorize_pulse_owner
      return if @pulse.grid_hackr_id == current_hackr.id

      render json: {
        success: false,
        error: "You are not authorized to delete this pulse"
      }, status: :forbidden
    end

    def require_admin
      return if current_hackr&.admin?

      render json: {
        success: false,
        error: "Admin access required"
      }, status: :forbidden
    end

    def pulse_params
      params.require(:pulse).permit(:content, :parent_pulse_id)
    end

    def pulse_json(pulse)
      {
        id: pulse.id,
        content: pulse.content,
        pulsed_at: pulse.pulsed_at,
        echo_count: pulse.echo_count,
        splice_count: pulse.splices.count, # Real-time count
        signal_dropped: pulse.signal_dropped,
        signal_dropped_at: pulse.signal_dropped_at,
        parent_pulse_id: pulse.parent_pulse_id,
        thread_root_id: pulse.thread_root_id,
        is_splice: pulse.is_splice?,
        is_echoed_by_current_hackr: logged_in? ? pulse.is_echo_by?(current_hackr) : false,
        current_hackr_is_logged_in: logged_in?,
        current_hackr_is_admin: logged_in? ? current_hackr.admin? : false,
        grid_hackr: {
          id: pulse.grid_hackr.id,
          hackr_alias: pulse.grid_hackr.hackr_alias,
          role: pulse.grid_hackr.role
        },
        created_at: pulse.created_at,
        updated_at: pulse.updated_at
      }
    end

    def broadcast_pulse(pulse, type)
      ActionCable.server.broadcast("pulse_wire", {
        type: type,
        pulse: pulse_json(pulse)
      })
    end
  end
end
