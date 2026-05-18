# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_05_17_200002) do
  create_table "analytics_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_name", null: false
    t.string "event_type", null: false
    t.integer "hackr_id"
    t.text "properties"
    t.string "session_id", limit: 36, null: false
    t.index ["created_at"], name: "index_analytics_events_on_created_at"
    t.index ["event_type"], name: "index_analytics_events_on_event_type"
    t.index ["session_id"], name: "index_analytics_events_on_session_id"
  end

  create_table "performance_metrics", force: :cascade do |t|
    t.string "connection_type", limit: 32
    t.datetime "created_at", null: false
    t.string "device_class", limit: 16
    t.integer "hackr_id"
    t.string "metric_name", null: false
    t.string "metric_type", null: false
    t.string "page_path", null: false
    t.string "session_id", limit: 64
    t.string "unit", null: false
    t.datetime "updated_at", null: false
    t.float "value", null: false
    t.index ["created_at"], name: "index_performance_metrics_on_created_at"
    t.index ["metric_name"], name: "index_performance_metrics_on_metric_name"
  end
end
