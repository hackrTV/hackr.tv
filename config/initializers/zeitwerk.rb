# frozen_string_literal: true

# Configure Zeitwerk autoloader inflections for acronyms
Rails.autoloaders.main.inflector.inflect(
  "ansi" => "ANSI"
)
