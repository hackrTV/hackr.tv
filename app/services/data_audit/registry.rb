# frozen_string_literal: true

module DataAudit
  module Registry
    CHECKS = [
      # Grid — Critical
      DataAudit::Checks::MissionNoGiver,
      DataAudit::Checks::MissionBlockedPrereq,
      DataAudit::Checks::BreachEncounterOrphaned,
      DataAudit::Checks::RegionMissingHospital,

      # Grid — Warning
      DataAudit::Checks::RoomNoExits,
      DataAudit::Checks::MissionNoObjectives,
      DataAudit::Checks::SchematicNoIngredients,
      DataAudit::Checks::BreachTemplateNoProtocols,
      DataAudit::Checks::VendorNoListings,
      DataAudit::Checks::QuestGiverNoMissions,
      DataAudit::Checks::ZoneNoRooms,

      # Music — Info
      DataAudit::Checks::ReleaseNoCover,
      DataAudit::Checks::ReleaseNoTracks,
      DataAudit::Checks::TrackNoAudio,

      # Grid — Info
      DataAudit::Checks::RoomNoDescription
    ].freeze
  end
end
