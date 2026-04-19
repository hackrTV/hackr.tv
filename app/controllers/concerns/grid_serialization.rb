module GridSerialization
  extend ActiveSupport::Concern

  private

  def auth_hackr_json(hackr)
    {
      id: hackr.id,
      hackr_alias: hackr.hackr_alias,
      email: hackr.email,
      role: hackr.role,
      current_room: hackr.current_room ? auth_room_json(hackr.current_room) : nil,
      features: hackr.admin? ? [FeatureGrant::PULSE_GRID] : hackr.feature_grants.pluck(:feature),
      otp_enabled: hackr.otp_required_for_login?
    }
  end

  def auth_room_json(room)
    {
      id: room.id,
      name: room.name,
      description: room.description
    }
  end
end
