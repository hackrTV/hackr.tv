# frozen_string_literal: true

require "rails_helper"

RSpec.describe Terminal::Handlers::BandsHandler do
  let(:input) { StringIO.new }
  let(:output) { StringIO.new }
  let(:session) { Terminal::Session.new(input, output) }

  subject(:handler) { described_class.new(session) }

  before do
    create(:artist, name: "Alpha Synth", slug: "alpha-synth", genre: "Synthwave")
    create(:artist, name: "Zulu Synth", slug: "zulu-synth", genre: "Synthwave", position: 1)
  end

  after do
    session.realtime.clear_callbacks
  end

  it "lists bands in the roster order" do
    handler.handle("list")

    expect(output.string.index("Zulu Synth")).to be < output.string.index("Alpha Synth")
  end

  it "returns search results in the roster order" do
    handler.handle("search synthwave")

    expect(output.string.index("Zulu Synth")).to be < output.string.index("Alpha Synth")
  end
end
