# == Schema Information
#
# Table name: emotes
# Database name: primary
#
#  id         :integer          not null, primary key
#  enabled    :boolean          default(TRUE), not null
#  slug       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_emotes_on_slug  (slug) UNIQUE
#
FactoryBot.define do
  factory :emote do
    sequence(:slug) { |n| "emote_#{n}" }
    enabled { true }

    # Emotes require an image on create; attach the PNG fixture by default.
    after(:build) do |emote|
      next if emote.image.attached?
      emote.image.attach(
        io: File.open(Rails.root.join("spec", "fixtures", "files", "test_emote.png")),
        filename: "test_emote.png",
        content_type: "image/png"
      )
    end

    trait :gif do
      after(:build) do |emote|
        emote.image.attach(
          io: File.open(Rails.root.join("spec", "fixtures", "files", "test_emote.gif")),
          filename: "test_emote.gif",
          content_type: "image/gif"
        )
      end
    end

    # 168x56 PNG (3:1) for the aspect-ratio paths.
    trait :wide do
      after(:build) do |emote|
        emote.image.attach(
          io: File.open(Rails.root.join("spec", "fixtures", "files", "test_emote_wide.png")),
          filename: "test_emote_wide.png",
          content_type: "image/png"
        )
      end
    end

    trait :disabled do
      enabled { false }
    end
  end
end
