# frozen_string_literal: true

class AddSessionIdIndexToAnalyticsEvents < ActiveRecord::Migration[8.1]
  def change
    add_index :analytics_events, :session_id
  end
end
