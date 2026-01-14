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
    policy.script_src :self, :https
    policy.style_src :self, :https
    policy.connect_src :self, :https, :wss
    policy.frame_src :self, "https://www.youtube.com", "https://www.youtube-nocookie.com"

    if Rails.env.development?
      vite_host = ViteRuby.config.host_with_port
      policy.script_src(*policy.script_src, :unsafe_eval, "http://#{vite_host}")
      policy.style_src(*policy.style_src, :unsafe_inline)
      policy.connect_src(*policy.connect_src, "ws://#{vite_host}", "http://#{vite_host}")
    end

    policy.script_src(*policy.script_src, :blob) if Rails.env.test?
  end

  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src style-src]
end
