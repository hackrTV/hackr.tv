# frozen_string_literal: true

module LiveWatch
  # Closes watch sessions abandoned without a clean unsubscribe (lost
  # socket, crashed tab). Dates each close to the session's last good
  # heartbeat so idle time after the disconnect isn't credited.
  class SweepJob < ApplicationJob
    queue_as :default

    def perform
      HackrWatchSession.close_stale!
    end
  end
end
