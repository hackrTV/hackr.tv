# frozen_string_literal: true

module StructuredLogging
  extend ActiveSupport::Concern

  # Injects hackr identity into the lograge payload via the standard
  # Rails append_info_to_payload hook. This data is available in
  # event.payload inside lograge's custom_options block.
  def append_info_to_payload(payload)
    super
    hackr = current_hackr
    payload[:hackr_id] = hackr&.id
    payload[:hackr_alias] = hackr&.hackr_alias
  end
end
