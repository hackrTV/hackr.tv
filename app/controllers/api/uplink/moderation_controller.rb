module Api
  module Uplink
    class ModerationController < ApplicationController
      include GridAuthentication

      before_action :require_login_api
      before_action :require_operator, except: [:moderation_log]
      before_action :require_admin, only: [:blackout]
      before_action :set_target_hackr, only: %i[squelch blackout lift_punishment]

      # POST /api/uplink/users/:id/squelch
      def squelch
        duration = params[:duration_minutes]&.to_i
        reason = params[:reason]

        if UserPunishment.squelched?(@target)
          return render json: {
            success: false,
            error: "User is already squelched"
          }, status: :unprocessable_entity
        end

        UserPunishment.squelch!(
          @target,
          issued_by: current_hackr,
          duration_minutes: duration,
          reason: reason
        )

        render json: {
          success: true,
          message: "#{@target.hackr_alias} has been squelched#{duration ? " for #{duration} minutes" : " permanently"}"
        }
      end

      # POST /api/uplink/users/:id/blackout
      def blackout
        duration = params[:duration_minutes]&.to_i
        reason = params[:reason]

        if UserPunishment.blackedout?(@target)
          return render json: {
            success: false,
            error: "User is already blackedout"
          }, status: :unprocessable_entity
        end

        UserPunishment.blackout!(
          @target,
          issued_by: current_hackr,
          duration_minutes: duration,
          reason: reason
        )

        render json: {
          success: true,
          message: "#{@target.hackr_alias} has been blackedout#{duration ? " for #{duration} minutes" : " permanently"}"
        }
      end

      # DELETE /api/uplink/users/:id/punishment
      def lift_punishment
        punishment_type = params[:punishment_type]

        punishments = UserPunishment.active_for(@target, punishment_type)

        if punishments.empty?
          return render json: {
            success: false,
            error: "No active punishment found for this user"
          }, status: :not_found
        end

        punishments.each { |p| p.lift!(current_hackr) }

        render json: {
          success: true,
          message: "Punishment lifted for #{@target.hackr_alias}"
        }
      end

      # GET /api/uplink/moderation_log
      def moderation_log
        unless current_hackr.at_least_operator?
          return render json: {
            success: false,
            error: "Operator access required"
          }, status: :forbidden
        end

        logs = ModerationLog.recent.includes(:actor, :target, :chat_message)

        # Filter by action type
        logs = logs.by_action(params[:action_type]) if params[:action_type].present?

        # Filter by actor
        if params[:actor_id].present?
          logs = logs.by_actor(params[:actor_id])
        end

        # Filter by target
        if params[:target_id].present?
          logs = logs.by_target(params[:target_id])
        end

        # Pagination
        page = [params[:page].to_i, 1].max
        per_page = params[:per_page].to_i.clamp(20, 100)

        total = logs.count
        logs = logs.limit(per_page).offset((page - 1) * per_page)

        render json: {
          logs: logs.map { |log| log_json(log) },
          meta: {
            total: total,
            page: page,
            per_page: per_page,
            total_pages: (total.to_f / per_page).ceil
          }
        }
      end

      private

      def set_target_hackr
        @target = GridHackr.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          success: false,
          error: "User not found"
        }, status: :not_found
      end

      def require_operator
        return if current_hackr.at_least_operator?

        render json: {
          success: false,
          error: "Operator access required"
        }, status: :forbidden
      end

      def require_admin
        return if current_hackr.at_least_admin?

        render json: {
          success: false,
          error: "Admin access required"
        }, status: :forbidden
      end

      def log_json(log)
        {
          id: log.id,
          action: log.action,
          reason: log.reason,
          duration_minutes: log.duration_minutes,
          created_at: log.created_at.iso8601,
          actor: {
            id: log.actor_id,
            hackr_alias: log.actor&.hackr_alias
          },
          target: log.target ? {
            id: log.target_id,
            hackr_alias: log.target.hackr_alias
          } : nil,
          chat_message_id: log.chat_message_id
        }
      end
    end
  end
end
