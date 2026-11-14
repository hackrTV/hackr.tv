class TracksController < ApplicationController
  # Legacy redirects for old /trackz routes
  # All track functionality now handled by React SPA via pages#spa_root

  # Legacy redirect for /trackz -> /thecyberpulse/releases
  def legacy_redirect
    redirect_to "/thecyberpulse/releases", status: 301
  end

  # Legacy redirect for /trackz/:id -> /<owning artist>/trackz/:id; TCP wins
  # a shared slug, and an unknown id lands on TCP's SIGNAL LOST.
  def legacy_redirect_show
    id = params[:id].to_s
    owners = Track.joins(:artist).where(slug: id).pluck("artists.slug")
    owners = Track.joins(:artist).where(id: id).pluck("artists.slug") if owners.empty? && id.match?(/\A\d+\z/)
    owner = owners.include?("thecyberpulse") ? "thecyberpulse" : owners.first || "thecyberpulse"
    redirect_to "/#{owner}/trackz/#{id}", status: 301
  end
end
