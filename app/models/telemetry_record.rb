# frozen_string_literal: true

# Abstract base class for models stored in the telemetry SQLite database.
# Isolates high-frequency perf + analytics writes from the primary DB.
class TelemetryRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: {writing: :telemetry, reading: :telemetry}
end
