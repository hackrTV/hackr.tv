class AchievementChannel < ApplicationCable::Channel
  def self.stream_name_for(hackr)
    "achievement_channel_#{hackr.id}"
  end

  def subscribed
    unless current_hackr
      reject
      return
    end
    stream_from self.class.stream_name_for(current_hackr)
  end
end
