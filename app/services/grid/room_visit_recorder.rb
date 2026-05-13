# frozen_string_literal: true

module Grid
  module RoomVisitRecorder
    def self.record!(hackr:, room:)
      return unless hackr && room

      GridRoomVisit.find_or_create_by!(
        grid_hackr: hackr,
        grid_room: room
      ) do |v|
        v.first_visited_at = Time.current
      end
    rescue ActiveRecord::RecordNotUnique
      # Race condition: another request inserted first. Idempotent — ignore.
    end

    def self.record_by_id!(hackr:, room_id:)
      return unless hackr && room_id

      GridRoomVisit.find_or_create_by!(
        grid_hackr_id: hackr.id,
        grid_room_id: room_id
      ) do |v|
        v.first_visited_at = Time.current
      end
    rescue ActiveRecord::RecordNotUnique
      # Race condition: another request inserted first. Idempotent — ignore.
    end
  end
end
