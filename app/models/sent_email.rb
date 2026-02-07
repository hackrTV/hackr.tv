class SentEmail < ApplicationRecord
  belongs_to :emailable, polymorphic: true, optional: true
end
