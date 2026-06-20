module Api
  # Public, read-only WIRE profile data for the overhauled /wire/:alias
  # page. No auth required; when the viewer is logged in and owns the
  # profile, `is_self` unlocks inline editing affordances on the client.
  class ProfilesController < ApplicationController
    include GridAuthentication
    include PulseSerialization

    # last_active is coarsened to this granularity so the public endpoint
    # can't be polled for fine-grained presence tracking.
    LAST_ACTIVE_GRANULARITY = 5.minutes

    # GET /api/profiles/:alias
    def show
      hackr = GridHackr.where("LOWER(hackr_alias) = ?", params[:alias].to_s.downcase).first

      return render json: {error: "No such hackr"}, status: :not_found unless hackr

      render json: {
        profile: public_hackr_json(hackr),
        is_self: logged_in? && current_hackr.id == hackr.id
      }
    end

    private

    def public_hackr_json(hackr)
      {
        id: hackr.id,
        hackr_alias: hackr.hackr_alias,
        role: hackr.role,
        bio: hackr.bio,
        clearance: hackr.stat("clearance").to_i,
        joined_at: hackr.created_at,
        last_active_at: coarse_last_active(hackr.last_activity_at),
        stats: Grid::ProfileStats.for(hackr),
        pinned_pulses: pinned_pulses_json(hackr)
      }
    end

    def coarse_last_active(time)
      return nil unless time

      step = LAST_ACTIVE_GRANULARITY.to_i
      Time.zone.at((time.to_i / step) * step)
    end
  end
end
