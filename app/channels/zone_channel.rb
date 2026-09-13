class ZoneChannel < ApplicationCable::Channel
  def self.stream_name_for(zone_id)
    "zone_channel_#{zone_id}"
  end

  def subscribed
    unless current_hackr
      reject
      return
    end

    # Admin preview (controlled rollout): the grid is admin-only for now
    # — remove this check when the tactical surface reopens.
    unless current_hackr.admin?
      reject
      return
    end

    current_hackr.reload
    zone_id = current_hackr.current_room&.grid_zone_id

    unless zone_id
      reject
      return
    end

    stream_from self.class.stream_name_for(zone_id)
  end
end
