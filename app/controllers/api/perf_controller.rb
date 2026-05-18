# frozen_string_literal: true

module Api
  class PerfController < ApplicationController
    # sendBeacon does not send CSRF tokens
    protect_from_forgery with: :null_session

    MAX_BATCH_SIZE = 50

    # POST /api/perf/metrics
    def create
      metrics = params[:metrics]

      unless metrics.is_a?(Array) && metrics.size.between?(1, MAX_BATCH_SIZE)
        return render json: {error: "invalid payload"}, status: :bad_request
      end

      rows = metrics.filter_map do |m|
        name = m[:metric_name].to_s
        type = m[:metric_type].to_s
        next unless PerformanceMetric::VALID_METRIC_NAMES.include?(name)
        next unless PerformanceMetric::VALID_METRIC_TYPES.include?(type)

        {
          metric_name: name,
          metric_type: type,
          value: m[:value].to_f,
          unit: m[:unit].to_s.presence_in(%w[ms score]) || "ms",
          page_path: m[:page_path].to_s.first(255),
          session_id: m[:session_id].to_s.first(64),
          hackr_id: current_hackr&.id,
          connection_type: m[:connection_type].to_s.first(32).presence,
          device_class: m[:device_class].to_s.first(16).presence,
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      PerformanceMetric.insert_all(rows) if rows.any?

      render json: {received: rows.size}, status: :created
    end
  end
end
