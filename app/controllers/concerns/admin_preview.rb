# Controlled-rollout gate (2026-09): surfaces slated for public release
# but restricted to admins for now. Layered ON TOP of the existing
# login/feature-grant gates, which stay in place — delete a controller's
# admin_preview! line (or require_admin_preview_api before_action, or
# the channel-side admin checks) to reopen the surface and let the
# underlying gates resume. /root is NOT this: the admin namespace is
# permanently admin-only via require_admin.
#
# Admins passing the gate get @admin_preview, which the application
# layout renders as the ADMIN PREVIEW banner
# (shared/_admin_preview_banner).
module AdminPreview
  extend ActiveSupport::Concern

  class_methods do
    # Gates every action (or an `only:`/`except:` subset) behind the
    # admin role. `title:` brands the coming-soon page non-admins see.
    def admin_preview!(title: "THE PULSE GRID", **options)
      before_action(**options) { require_admin_preview(title: title) }
    end
  end

  private

  def require_admin_preview(title:)
    if admin_hackr?
      @admin_preview = true
      return
    end

    respond_to do |format|
      format.html do
        @preview_title = title
        render "shared/coming_soon"
      end
      format.json { render_admin_preview_forbidden }
      format.any { head :forbidden }
    end
  end

  # JSON-only variant for the Api:: controllers.
  def require_admin_preview_api
    return if admin_hackr?

    render_admin_preview_forbidden
  end

  def render_admin_preview_forbidden
    render json: {
      success: false,
      error: "This feature has not opened to the public yet."
    }, status: :forbidden
  end
end
