require "rails_helper"

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
# Chat emotes: slug rules, upload validation, the gif-vs-variant serving
# split, the cached render map the renderers + composers share, and the
# request-free partial rendering the Turbo broadcasts depend on.
RSpec.describe Emote, type: :model do
  describe "slug" do
    it "normalizes to lowercase and strips whitespace" do
      emote = create(:emote, slug: "  WaVe ")

      expect(emote.slug).to eq("wave")
      expect(emote.token).to eq(":wave:")
      expect(emote.to_param).to eq("wave")
    end

    it "requires 2-32 chars of a-z, 0-9, _ with at least one letter" do
      expect(build(:emote, slug: "a")).not_to be_valid
      expect(build(:emote, slug: "x" * 33)).not_to be_valid
      expect(build(:emote, slug: "no-dash")).not_to be_valid
      expect(build(:emote, slug: "Has Space")).not_to be_valid
      expect(build(:emote, slug: "30")).not_to be_valid # would turn 12:30:45 into an emote
      expect(build(:emote, slug: "ok_2")).to be_valid
      expect(build(:emote, slug: "x" * 32)).to be_valid
    end

    it "is unique after normalization" do
      create(:emote, slug: "wave")
      dup = build(:emote, slug: "WAVE")

      expect(dup).not_to be_valid
      expect(dup.errors[:slug]).to include("has already been taken")
    end
  end

  describe "image" do
    it "is required on create" do
      emote = Emote.new(slug: "wave")

      expect(emote).not_to be_valid
      expect(emote.errors[:image]).to include("can't be blank")
    end

    it "accepts png and gif fixtures" do
      expect(build(:emote)).to be_valid
      expect(build(:emote, :gif)).to be_valid
    end

    it "rejects other content types" do
      emote = Emote.new(slug: "cover")
      emote.image.attach(io: File.open(Rails.root.join("spec/fixtures/files/test_cover.jpg")),
        filename: "test_cover.jpg", content_type: "image/jpeg")

      expect(emote).not_to be_valid
      expect(emote.errors[:image]).to include("must be a PNG, GIF, or WebP image")
    end

    it "rejects files over 512 KB" do
      emote = Emote.new(slug: "huge")
      emote.image.attach(io: StringIO.new("0" * (512.kilobytes + 1)), filename: "huge.png", content_type: "image/png")

      expect(emote).not_to be_valid
      expect(emote.errors[:image]).to include("must be 512 KB or smaller")
    end

    it "can be toggled without re-uploading" do
      emote = create(:emote, slug: "wave")

      expect(emote.update(enabled: false)).to be(true)
      expect(emote.image).to be_attached
    end
  end

  describe "#chat_image / #chat_url" do
    it "serves static images as a 56x56 webp variant via a representation path" do
      emote = create(:emote, slug: "wave")

      expect(emote).not_to be_gif
      expect(emote.chat_image).to be_a(ActiveStorage::VariantWithRecord)
      expect(emote.chat_url).to start_with("/rails/active_storage/representations/redirect/")
    end

    it "serves gifs as the original blob so animation survives" do
      emote = create(:emote, :gif, slug: "party")

      expect(emote).to be_gif
      expect(emote.chat_url).to start_with("/rails/active_storage/blobs/redirect/")
      expect(emote.chat_url).to end_with("/test_emote.gif")
    end
  end

  describe ".render_map" do
    it "maps only enabled emotes that have an image, keyed by slug" do
      create(:emote, slug: "wave")
      create(:emote, :disabled, slug: "off")
      bare = create(:emote, slug: "bare")
      bare.image.purge

      map = Emote.render_map

      expect(map.keys).to eq(["wave"])
      expect(map["wave"]).to start_with("/rails/active_storage/")
    end

    it "expires the cached map on every create/update/destroy" do
      allow(Rails.cache).to receive(:delete).and_call_original

      emote = create(:emote, slug: "wave")
      emote.update!(enabled: false)
      emote.destroy!

      expect(Rails.cache).to have_received(:delete).with(Emote::RENDER_MAP_CACHE_KEY).at_least(3).times
    end
  end

  describe "rendering outside a request (Turbo broadcasts)" do
    it "renders emote images into the packet partial with host-free paths" do
      create(:emote, slug: "wave")
      channel = create(:chat_channel, slug: "ambient")
      packet = create(:chat_message, chat_channel: channel, content: "o/ :wave:")

      html = ApplicationController.render(partial: "uplink/packet", locals: {packet: packet, viewer: nil})

      expect(html).to include('class="emote"')
      expect(html).to include('src="/rails/active_storage/representations/redirect/')
    end

    it "renders emote images into the pulse card the same way" do
      create(:emote, :gif, slug: "party")
      pulse = create(:pulse, content: "tonight :party:")

      html = ApplicationController.render(partial: "wire/pulse_card", locals: {pulse: pulse, viewer: nil, echoed: false})

      expect(html).to include('alt=":party:"')
      expect(html).to include('src="/rails/active_storage/blobs/redirect/')
    end
  end
end
