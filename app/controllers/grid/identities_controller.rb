# Server-rendered identity page (Hotwire migration Phase 2) — ports
# IdentityPage.tsx. Three independent forms post to their own endpoints
# (bio here; email change + password reset in their controllers) and
# come back with section-scoped x_* flash messages.
class Grid::IdentitiesController < ApplicationController
  before_action :require_login

  def show
    @bio = current_hackr.bio
  end

  # PATCH /grid/identity — bio save. Mirrors Api::GridController#update_identity.
  def update
    current_hackr.skip_reserved_check = true
    current_hackr.assign_attributes(identity_params)

    if current_hackr.save
      flash[:x_bio_notice] = "Bio updated."
      redirect_to grid_identity_path
    else
      @bio_error = current_hackr.errors[:bio].first || current_hackr.errors.full_messages.to_sentence
      @bio = identity_params[:bio]
      # Drop the rejected attributes so the rest of the page renders the
      # persisted hackr, not the invalid in-memory copy.
      current_hackr.reload
      render :show, status: :unprocessable_entity
    end
  end

  private

  def identity_params
    params.permit(:bio)
  end
end
