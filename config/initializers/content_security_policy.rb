# Be sure to restart your server when you modify this file.
#
# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src :self, :https, :data
    policy.img_src :self, :https, :data
    policy.media_src :self, :https, :http, :data
    policy.object_src :none
    policy.style_src :self, :https, :unsafe_inline
    policy.connect_src :self, :https, :wss
    policy.frame_src :self, "https://www.youtube.com", "https://www.youtube-nocookie.com"

    # Script sources - nonces handle inline scripts, so no :unsafe_inline needed
    # External CDN scripts (ActionCable, Sortable) are allowed via :https
    policy.script_src :self, :https

    if Rails.env.development?
      # Vite dev server needs additional permissions
      vite_host = ViteRuby.config.host_with_port
      policy.script_src(*policy.script_src, "http://#{vite_host}", :unsafe_eval)
      policy.connect_src(*policy.connect_src, "ws://#{vite_host}", "http://#{vite_host}")
    end

    policy.script_src(*policy.script_src, :blob) if Rails.env.test?
  end

  # Generate nonces for inline scripts
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  # Note: Don't include style-src in nonce_directives - it breaks inline styles
  # even with :unsafe_inline set, because nonce presence overrides unsafe-inline
  config.content_security_policy_nonce_directives = %w[script-src]
end
