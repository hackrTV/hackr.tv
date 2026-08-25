# Inline bio edit on the own wire profile (Phase 3) — turbo-frame form
# over the same model rules as Grid::IdentitiesController#update.
class Wire::BiosController < ApplicationController
  layout "hotwire"

  before_action :require_login
  before_action :require_self

  # GET /wire/:username/bio/edit (turbo frame)
  def edit
  end

  # PATCH /wire/:username/bio
  def update
    current_hackr.skip_reserved_check = true
    current_hackr.bio = params[:bio]

    if current_hackr.save
      # Turbo requires non-GET frame submissions to redirect (200 renders
      # show "Content missing"); it follows this and extracts the
      # profile-bio frame from the profile page.
      redirect_to wire_user_path(current_hackr.hackr_alias.downcase), status: :see_other
    else
      @error = current_hackr.errors[:bio].first || current_hackr.errors.full_messages.to_sentence
      current_hackr.reload
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def require_self
    return if current_hackr.hackr_alias.downcase == params[:username].to_s.downcase

    head :forbidden
  end
end
