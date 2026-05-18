# frozen_string_literal: true

class CreateErrorTracking < ActiveRecord::Migration[8.1]
  def change
    create_table :error_groups do |t|
      t.string :fingerprint, null: false
      t.string :title, null: false
      t.string :component, null: false # "backend" | "frontend"
      t.string :severity, null: false, default: "error" # "error" | "warning" | "info"
      t.string :status, null: false, default: "open" # "open" | "resolved" | "ignored"
      t.datetime :ignore_until
      t.integer :occurrence_count, null: false, default: 0
      t.datetime :first_seen_at
      t.datetime :last_seen_at
      t.datetime :resolved_at
      t.integer :resolved_by_hackr_id
      t.timestamps
    end

    add_index :error_groups, :fingerprint, unique: true
    add_index :error_groups, [:status, :last_seen_at]
    add_index :error_groups, :component
    add_index :error_groups, :severity

    create_table :error_occurrences do |t|
      t.references :error_group, null: false, foreign_key: true
      t.datetime :occurred_at, null: false
      t.string :component, null: false
      t.string :exception_class
      t.string :message, null: false
      t.text :backtrace # JSON array
      t.string :request_url
      t.string :request_method
      t.text :request_params # JSON, sanitized
      t.string :ip_address
      t.string :user_agent
      t.integer :hackr_id
      t.string :hackr_alias
      t.string :rails_env
      t.text :metadata # JSON, arbitrary context
      t.datetime :created_at, null: false
    end

    add_index :error_occurrences, [:error_group_id, :occurred_at], order: {occurred_at: :desc}
    add_index :error_occurrences, :occurred_at
  end
end
