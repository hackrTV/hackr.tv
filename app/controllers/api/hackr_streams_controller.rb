class Api::HackrStreamsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  # POST /api/artists/:artist_slug/vods/:id/watch — watch-credit ping
  # from the Hotwire vidz page (vod_player Stimulus controller). The
  # SPA-era read endpoints (show/schedule/index/vod_show) are retired
  # (Phase 7); those pages are server-rendered now.
  def watch
    return head :no_content unless current_hackr

    artist = Artist.find_by!(slug: params[:artist_slug])
    stream = artist.hackr_streams.find(params[:id])

    HackrVodWatch.record!(current_hackr, stream)
    Grid::AchievementChecker.new(current_hackr).check("vods_watched")

    head :no_content
  end

  private

  def record_not_found
    render json: {error: "Not found"}, status: :not_found
  end
end
