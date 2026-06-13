class Api::OverlayController < ApplicationController
  include GridAuthentication

  before_action :require_login_api, only: %i[set_now_playing]

  # POST /api/overlay/now-playing
  # Called by the React player when a track starts playing, pauses, or resumes
  def set_now_playing
    if params[:track_id].present?
      track = Track.find_by(id: params[:track_id])
      if track
        paused = params[:paused] == true || params[:paused] == "true"
        OverlayNowPlaying.set_track!(track, paused: paused)
        render json: {
          success: true,
          now_playing: {
            track_id: track.id,
            title: track.title,
            artist: track.artist&.name,
            album: track.release&.name,
            paused: paused
          }
        }
      else
        render json: {success: false, error: "Track not found"}, status: :not_found
      end
    elsif params.key?(:paused) && params[:track_id].nil?
      # Update paused state for current track
      paused = params[:paused] == true || params[:paused] == "true"
      OverlayNowPlaying.set_paused!(paused)
      render json: {success: true, paused: paused}
    elsif params[:clear].present?
      OverlayNowPlaying.clear!
      render json: {success: true, now_playing: nil}
    else
      render json: {success: false, error: "Missing track_id, paused, or clear parameter"}, status: :bad_request
    end
  end

  # GET /api/overlay/now-playing
  def now_playing
    render json: OverlayNowPlaying.current.as_api_json(base_url: request.base_url)
  end

  # GET /api/overlay/tickers
  def tickers
    scope = OverlayTicker.ordered
    scope = filter_active(scope)
    scope = scope.where(slug: params[:slug]) if params[:slug].present?

    render json: {
      tickers: scope.map { |t| ticker_json(t) }
    }
  end

  # GET /api/overlay/lower-thirds
  def lower_thirds
    scope = OverlayLowerThird.order(name: :asc)
    scope = filter_active(scope)
    scope = scope.where(slug: params[:slug]) if params[:slug].present?

    render json: {
      lower_thirds: scope.map { |lt| lower_third_json(lt) }
    }
  end

  # GET /api/overlay/scenes
  def scenes
    scope = OverlayScene.ordered
    scope = filter_active(scope)

    if params[:group].present?
      scene_ids = OverlaySceneGroupScene
        .joins(:overlay_scene_group)
        .where(overlay_scene_groups: {slug: params[:group]})
        .select(:overlay_scene_id)
      scope = scope.where(id: scene_ids)
    end

    render json: {
      scenes: scope.includes(:overlay_scene_elements, :overlay_scene_groups).map { |s|
        {
          slug: s.slug,
          name: s.name,
          scene_type: s.scene_type,
          width: s.width,
          height: s.height,
          active: s.active,
          element_count: s.overlay_scene_elements.size,
          groups: s.overlay_scene_groups.map(&:slug)
        }
      }
    }
  end

  # GET /api/overlay/scenes/:slug
  def scene
    scene = OverlayScene.active.find_by(slug: params[:slug])
    return render json: {error: "Scene not found"}, status: :not_found unless scene

    elements = scene.overlay_scene_elements
      .includes(:overlay_element)
      .order(z_index: :asc)

    render json: {
      scene: {
        slug: scene.slug,
        name: scene.name,
        scene_type: scene.scene_type,
        width: scene.width,
        height: scene.height,
        active: scene.active,
        settings: scene.settings || {},
        elements: elements.filter_map { |se|
          el = se.overlay_element
          next unless el
          {
            element_name: el.name,
            element_slug: el.slug,
            element_type: el.element_type,
            x: se.x,
            y: se.y,
            width: se.width,
            height: se.height,
            z_index: se.z_index,
            settings: el.settings || {},
            overrides: se.overrides || {}
          }
        }
      }
    }
  end

  # GET /api/overlay/scene-groups
  def scene_groups
    groups = OverlaySceneGroup.ordered
      .includes(overlay_scene_group_scenes: :overlay_scene)

    render json: {
      scene_groups: groups.map { |g|
        {
          slug: g.slug,
          name: g.name,
          scenes: g.overlay_scene_group_scenes.filter_map { |sgs|
            next unless sgs.overlay_scene
            {slug: sgs.overlay_scene.slug, position: sgs.position}
          }
        }
      }
    }
  end

  # GET /api/overlay/elements
  def elements
    scope = OverlayElement.order(name: :asc)
    scope = filter_active(scope)

    render json: {
      elements: scope.map { |e|
        {
          slug: e.slug,
          name: e.name,
          element_type: e.element_type,
          active: e.active,
          settings: e.settings || {}
        }
      }
    }
  end

  # GET /api/overlay/alerts/pending
  def alerts_pending
    render json: {
      alerts: OverlayAlert.pending.order(created_at: :asc).map(&:as_broadcast_json)
    }
  end

  private

  def ticker_json(ticker)
    {
      slug: ticker.slug,
      name: ticker.name,
      content: ticker.content,
      content_type: ticker.content_type,
      feed_source: ticker.feed_source,
      direction: ticker.direction,
      speed: ticker.speed,
      active: ticker.active
    }
  end

  def lower_third_json(lt)
    {
      slug: lt.slug,
      name: lt.name,
      primary_text: lt.primary_text,
      secondary_text: lt.secondary_text,
      logo_url: lt.logo_url,
      active: lt.active
    }
  end

  def filter_active(scope)
    if params[:active] == "all"
      scope
    else
      scope.active
    end
  end
end
