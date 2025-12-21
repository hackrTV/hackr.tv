require_relative "../../lib/middleware/lowercase_redirect"

Rails.application.config.middleware.insert_before 0, LowercaseRedirect
