# Non-production playground for the Hotwire migration (Phase 0).
# The smoke page proves the hotwire layout/entrypoint; the player pages are
# spike A (data-turbo-permanent audio across Turbo visits, feeds Phase 4);
# the map page is spike B (server-rendered SVG zone map, feeds Phase 6c).
# Routes exist only outside production.
class HotwireSpikesController < ApplicationController
  layout "hotwire"

  def smoke
  end

  def player_a
  end

  def player_b
  end

  # Same-page redirect so a form submit exercises a Turbo page refresh
  # (morph) with the permanent player present.
  def player_refresh
    redirect_to hotwire_spike_player_a_path
  end

  def audio
    # Real decodable audio (test_audio.mp3 is a zero-byte-filled stub);
    # 2s 440Hz tone, looped client-side.
    send_file Rails.root.join("spec/fixtures/files/spike_tone.ogg"),
      type: "audio/ogg", disposition: "inline"
  end

  def map
    @hackr = GridHackr.find_by(id: params[:hackr_id]) || current_hackr || GridHackr.first
    zone = GridZone.find_by(id: params[:zone_id]) || @hackr&.current_room&.grid_zone

    unless @hackr && zone
      render plain: "Spike needs a hackr with a current room (or ?hackr_id= & ?zone_id=).",
        status: :unprocessable_entity
      return
    end

    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    @map = Grid::ZoneMapBuilder.new(zone: zone, hackr: @hackr).build
    @build_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) * 1000).round(1)
  end
end
