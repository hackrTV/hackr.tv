# frozen_string_literal: true

module Analytics
  # Computes analytics metrics from existing hackr.tv data tables.
  # All queries are cached via Solid Cache with configurable TTL.
  class GridMetricsService
    CACHE_TTL = ENV.fetch("ANALYTICS_CACHE_TTL_MINUTES", "10").to_i.minutes
    CACHE_NS = "analytics_v1"

    def initialize(range_days:)
      @range_days = range_days
      @since = (range_days == 0) ? nil : range_days.days.ago
    end

    def user_metrics
      fetch_cached("user_metrics") { compute_user_metrics }
    end

    def feature_usage
      fetch_cached("feature_usage") { compute_feature_usage }
    end

    def tutorial_funnel
      fetch_cached("tutorial_funnel") { compute_tutorial_funnel }
    end

    def session_metrics
      fetch_cached("session_metrics") { compute_session_metrics }
    end

    def registrations_by_day(days: 30)
      fetch_cached("registrations_by_day_#{days}") { compute_time_series(:created_at, days) }
    end

    def activity_by_day(days: 30)
      fetch_cached("activity_by_day_#{days}") { compute_time_series(:last_activity_at, days) }
    end

    def analytics_event_count
      fetch_cached("analytics_event_count") { AnalyticsEvent.count }
    end

    def perf_summary
      fetch_cached("perf_summary") { compute_perf_summary }
    end

    private

    def fetch_cached(key, &block)
      Rails.cache.fetch("#{CACHE_NS}/#{key}/#{@since&.to_i || 0}", expires_in: CACHE_TTL, &block)
    end

    def compute_user_metrics
      dau = GridHackr.where("last_activity_at >= ?", 1.day.ago).count
      wau = GridHackr.where("last_activity_at >= ?", 7.days.ago).count
      mau = GridHackr.where("last_activity_at >= ?", 30.days.ago).count
      total = GridHackr.count

      returning = GridHackr
        .where("last_activity_at >= ?", 30.days.ago)
        .where("created_at < ?", 30.days.ago)
        .count
      new_30d = GridHackr.where("created_at >= ?", 30.days.ago).count

      {dau: dau, wau: wau, mau: mau, total: total, returning_30d: returning, new_30d: new_30d}
    end

    def compute_feature_usage
      top_rooms = GridRoomVisit
        .joins("INNER JOIN grid_rooms ON grid_rooms.id = grid_room_visits.grid_room_id")
        .joins("INNER JOIN grid_zones ON grid_zones.id = grid_rooms.grid_zone_id")
        .select("grid_rooms.name AS room_name, grid_zones.name AS zone_name, COUNT(*) AS visit_count")
        .then { |q| @since ? q.where("grid_room_visits.first_visited_at >= ?", @since) : q }
        .group("grid_room_visits.grid_room_id")
        .order("visit_count DESC")
        .limit(10)
        .map { |r| {name: "#{r.room_name} (#{r.zone_name})", count: r.visit_count} }

      top_tracks = GridHackrTrackPlay
        .joins("INNER JOIN tracks ON tracks.id = grid_hackr_track_plays.track_id")
        .joins("INNER JOIN artists ON artists.id = tracks.artist_id")
        .select("tracks.title, artists.name AS artist_name, SUM(grid_hackr_track_plays.play_count) AS total_plays")
        .then { |q| @since ? q.where("grid_hackr_track_plays.first_played_at >= ?", @since) : q }
        .group("grid_hackr_track_plays.track_id")
        .order("total_plays DESC")
        .limit(10)
        .map { |r| {name: "#{r.title} — #{r.artist_name}", count: r.total_plays} }

      breach_scope = GridHackrBreach.then { |q| @since ? q.where("started_at >= ?", @since) : q }
      breach_attempts = breach_scope.count
      breach_successes = breach_scope.where(state: "success").count

      shop_scope = GridShopTransaction.then { |q| @since ? q.where("created_at >= ?", @since) : q }
      shop_buys = shop_scope.where(transaction_type: "buy").count
      shop_sells = shop_scope.where(transaction_type: "sell").count

      mission_scope = GridHackrMission.then { |q| @since ? q.where("accepted_at >= ?", @since) : q }
      mission_accepted = mission_scope.count
      mission_completions = mission_scope.where(status: "completed").count

      {
        top_rooms: top_rooms,
        top_tracks: top_tracks,
        breach_attempts: breach_attempts,
        breach_successes: breach_successes,
        breach_success_rate: (breach_attempts > 0) ? (breach_successes.to_f / breach_attempts * 100).round(1) : 0,
        shop_buys: shop_buys,
        shop_sells: shop_sells,
        mission_accepted: mission_accepted,
        mission_completions: mission_completions,
        mission_completion_rate: (mission_accepted > 0) ? (mission_completions.to_f / mission_accepted * 100).round(1) : 0
      }
    end

    def compute_tutorial_funnel
      hackrs_with_tutorial = GridHackr.where("json_extract(stats, '$.tutorial_step') IS NOT NULL")
      total_started = hackrs_with_tutorial.count
      return {total_started: 0, step_counts: [], drop_off_step: nil} if total_started.zero?

      step_counts = GridHackr
        .where("json_extract(stats, '$.tutorial_step') IS NOT NULL")
        .group("json_extract(stats, '$.tutorial_step')")
        .order(Arel.sql("json_extract(stats, '$.tutorial_step') ASC"))
        .count("id")
        .transform_keys { |k| k.to_i }
        .sort_by { |step, _| step }

      # Completed = step 53 (final step)
      completed = step_counts.find { |s, _| s >= 53 }&.last || 0

      # Largest step-over-step drop: find consecutive pair with biggest count decrease
      drop_off_step = nil
      if step_counts.size > 1
        max_drop = 0
        step_counts.each_cons(2) do |(step_a, count_a), (step_b, count_b)|
          next if step_a >= 53
          drop = count_a - count_b
          if drop > max_drop
            max_drop = drop
            drop_off_step = step_a
          end
        end
      end

      {total_started: total_started, completed: completed, step_counts: step_counts, drop_off_step: drop_off_step}
    end

    def compute_session_metrics
      base = TerminalSession.where.not(duration_seconds: nil)
      base = base.where("connected_at >= ?", @since) if @since

      avg_duration = base.average(:duration_seconds)&.to_i || 0
      total_sessions = base.count
      unique_users = base.where.not(grid_hackr_id: nil).distinct.count(:grid_hackr_id)
      avg_sessions_per_user = (unique_users > 0) ? (total_sessions.to_f / unique_users).round(1) : 0

      {avg_duration_seconds: avg_duration, total_sessions: total_sessions,
       unique_users: unique_users, avg_sessions_per_user: avg_sessions_per_user}
    end

    ALLOWED_TIME_SERIES_COLUMNS = %w[created_at last_activity_at].freeze

    def compute_time_series(column, days)
      col = column.to_s
      raise ArgumentError, "Invalid column: #{col}" unless ALLOWED_TIME_SERIES_COLUMNS.include?(col)

      buckets = days.times.map { |i|
        date = i.days.ago.to_date
        [date.iso8601, 0]
      }.to_h

      GridHackr
        .where("#{col} >= ?", days.days.ago) # rubocop:disable Rails/WhereEquals -- column is allowlisted above
        .group("strftime('%Y-%m-%d', #{col})") # rubocop:disable Rails/GroupByAssociation -- raw SQLite strftime
        .count
        .each { |date, count| buckets[date] = count if buckets.key?(date) }

      buckets.sort.map { |date, count| {date: date, count: count} }
    end

    def compute_perf_summary
      {
        total_metrics: PerformanceMetric.count,
        web_vitals_24h: PerformanceMetric.web_vitals.where("created_at >= ?", 24.hours.ago).count,
        slow_zone_renders_7d: PerformanceMetric.slow_renders.where("created_at >= ?", 7.days.ago).count
      }
    end
  end
end
