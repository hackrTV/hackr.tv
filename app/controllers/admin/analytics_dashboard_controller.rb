# frozen_string_literal: true

class Admin::AnalyticsDashboardController < Admin::ApplicationController
  VALID_RANGES = {"7" => 7, "30" => 30, "90" => 90, "0" => 0}.freeze
  DEFAULT_RANGE = 30

  def index
    range_days = VALID_RANGES.fetch(params[:range], DEFAULT_RANGE)
    svc = Analytics::GridMetricsService.new(range_days: range_days)

    @range_days = range_days
    @user_metrics = svc.user_metrics
    @feature_usage = svc.feature_usage
    @tutorial_funnel = svc.tutorial_funnel
    @session_metrics = svc.session_metrics
    @registrations_by_day = svc.registrations_by_day(days: [range_days, 30].max.clamp(7, 90))
    @activity_by_day = svc.activity_by_day(days: [range_days, 30].max.clamp(7, 90))
    @analytics_event_count = svc.analytics_event_count
    @perf_summary = svc.perf_summary
  end
end
