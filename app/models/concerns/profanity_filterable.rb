# frozen_string_literal: true

# Shared concern for filtering profanity from user-generated content.
# When profanity is detected, submissions are rejected with a thematic
# GovCorp censorship message.
#
# Usage:
#   class Pulse < ApplicationRecord
#     include ProfanityFilterable
#     filter_profanity :content
#   end
#
module ProfanityFilterable
  extend ActiveSupport::Concern

  REJECTION_MESSAGES = [
    "GOVCORP CENSOR: Prohibited language detected. Transmission blocked.",
    "GOVCORP CENSOR: Content flagged by PRISM. Broadcast denied.",
    "GOVCORP CENSOR: Linguistic violation logged. Signal terminated.",
    "GOVCORP CENSOR: Unauthorized vocabulary detected. Packet dropped.",
    "GOVCORP CENSOR: Subversive language pattern identified. Purging transmission."
  ].freeze

  def self.rejection_message
    REJECTION_MESSAGES.sample
  end

  class_methods do
    # Declare which attributes should be checked for profanity.
    # Rejects the record if profanity is found.
    #
    # @param attributes [Array<Symbol>] The attribute names to filter
    #
    # Example:
    #   filter_profanity :content
    #   filter_profanity :content, :title
    #
    def filter_profanity(*attributes)
      @profanity_filtered_attributes ||= []
      @profanity_filtered_attributes.concat(attributes)

      validate :reject_profanity_content
    end

    def profanity_filtered_attributes
      @profanity_filtered_attributes || []
    end
  end

  private

  def reject_profanity_content
    self.class.profanity_filtered_attributes.each do |attr|
      value = public_send(attr)
      next if value.blank?

      if Obscenity.profane?(value)
        errors.add(attr, ProfanityFilterable.rejection_message)
      end
    end
  end
end
