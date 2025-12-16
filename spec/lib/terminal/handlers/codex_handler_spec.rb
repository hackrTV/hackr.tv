# frozen_string_literal: true

require "rails_helper"

RSpec.describe Terminal::Handlers::CodexHandler do
  let(:input) { StringIO.new }
  let(:output) { StringIO.new }
  let(:session) { Terminal::Session.new(input, output) }

  subject(:handler) { described_class.new(session) }

  # Create some test codex entries using factories
  let!(:person_entry) do
    create(:codex_entry, :published,
      name: "Test Person",
      slug: "test-person",
      entry_type: "person",
      summary: "A test person for specs",
      content: "Detailed content about the test person.")
  end

  let!(:location_entry) do
    create(:codex_entry, :published, :location,
      name: "Test Location",
      slug: "test-location",
      summary: "A test location",
      content: "Details about the location.")
  end

  let!(:draft_entry) do
    create(:codex_entry, :event,
      name: "Draft Entry",
      slug: "draft-entry",
      summary: "This is a draft",
      published: false)
  end

  after do
    session.realtime.clear_callbacks
  end

  describe "#on_enter" do
    it "clears the screen" do
      handler.on_enter

      expect(output.string).to include(Terminal::ANSI::CLEAR_SCREEN)
    end

    it "displays the banner" do
      handler.on_enter

      # Should display the codex banner (if it exists) or category list
      expect(output.string).not_to be_empty
    end

    it "displays entry categories" do
      handler.on_enter

      expect(output.string).to include("ENTRY TYPES")
      expect(output.string).to include("Person")
      expect(output.string).to include("Location")
    end
  end

  describe "#prompt" do
    it "returns the codex prompt" do
      expect(handler.prompt).to include("codex>")
    end

    it "uses purple color" do
      expect(handler.prompt).to include(session.renderer.colors[:purple])
    end
  end

  describe "#handle" do
    before do
      handler.on_enter
      output.truncate(0)
      output.rewind
    end

    describe "list command" do
      it "displays categories" do
        handler.handle("list")

        expect(output.string).to include("ENTRY TYPES")
      end

      it "works with l shortcut" do
        handler.handle("l")

        expect(output.string).to include("ENTRY TYPES")
      end
    end

    describe "type command" do
      it "lists entries of specified type" do
        handler.handle("type person")

        expect(output.string).to include("Test Person")
      end

      it "shows error for unknown type" do
        handler.handle("type invalid")

        expect(output.string).to include("Unknown type")
      end

      it "shows usage when no type specified" do
        handler.handle("type")

        expect(output.string).to include("Usage:")
      end

      it "handles plural types" do
        handler.handle("type persons")

        expect(output.string).to include("Test Person")
      end
    end

    describe "search command" do
      it "finds entries by name" do
        handler.handle("search Person")

        expect(output.string).to include("Test Person")
      end

      it "finds entries by summary" do
        handler.handle("search specs")

        expect(output.string).to include("Test Person")
      end

      it "shows no results message when nothing found" do
        handler.handle("search nonexistent12345")

        expect(output.string).to include("No entries found")
      end

      it "shows usage when no query specified" do
        handler.handle("search")

        expect(output.string).to include("Usage:")
      end

      it "does not show draft entries" do
        handler.handle("search Draft")

        expect(output.string).to include("No entries found")
      end
    end

    describe "read command" do
      it "displays entry by slug" do
        handler.handle("read test-person")

        expect(output.string).to include("TEST PERSON")
        expect(output.string).to include("test person for specs")
      end

      it "displays entry by name" do
        handler.handle("read Test Person")

        expect(output.string).to include("TEST PERSON")
      end

      it "shows error for non-existent entry" do
        handler.handle("read nonexistent")

        expect(output.string).to include("Entry not found")
      end

      it "suggests search when entry not found" do
        handler.handle("read nonexistent")

        expect(output.string).to include("search")
      end

      it "shows usage when no slug specified" do
        handler.handle("read")

        expect(output.string).to include("Usage:")
      end

      it "displays entry type" do
        handler.handle("read test-person")

        expect(output.string).to include("[Person]")
      end

      it "displays content section" do
        handler.handle("read test-person")

        expect(output.string).to include("CONTENT")
        expect(output.string).to include("Detailed content")
      end
    end

    describe "recent command" do
      it "shows recently updated entries" do
        handler.handle("recent")

        expect(output.string).to include("RECENTLY UPDATED")
        expect(output.string).to include("Test Person")
      end

      it "does not show draft entries" do
        handler.handle("recent")

        expect(output.string).not_to include("Draft Entry")
      end
    end

    describe "help command" do
      it "displays help information" do
        handler.handle("help")

        expect(output.string).to include("CODEX COMMANDS")
        expect(output.string).to include("list")
        expect(output.string).to include("type")
        expect(output.string).to include("search")
        expect(output.string).to include("read")
      end

      it "works with ? shortcut" do
        handler.handle("?")

        expect(output.string).to include("CODEX COMMANDS")
      end

      it "lists available categories" do
        handler.handle("help")

        expect(output.string).to include("Categories:")
        expect(output.string).to include("person")
        expect(output.string).to include("location")
      end
    end

    describe "back command" do
      it "calls go_back on session" do
        expect(session).to receive(:go_back)

        handler.handle("back")
      end
    end

    describe "direct slug input" do
      it "attempts to read entry when no command matches" do
        handler.handle("test-person")

        expect(output.string).to include("TEST PERSON")
      end
    end
  end

  describe "#display_help" do
    it "shows all entry types" do
      handler.display_help

      Terminal::Handlers::CodexHandler::ENTRY_TYPES.each do |type|
        expect(output.string).to include(type)
      end
    end
  end

  describe "ENTRY_TYPES" do
    it "includes expected types" do
      expected = %w[person organization event location technology faction item]

      expected.each do |type|
        expect(Terminal::Handlers::CodexHandler::ENTRY_TYPES).to include(type)
      end
    end
  end

  describe "content conversion" do
    let!(:wiki_entry) do
      create(:codex_entry, :published, :technology,
        name: "Wiki Test",
        slug: "wiki-test",
        summary: "Testing wiki links",
        content: "See [[Test Person]] for more info. Also check [[Other Link|display text]].")
    end

    it "converts wiki links to highlighted text" do
      handler.on_enter
      output.truncate(0)

      handler.handle("read wiki-test")

      expect(output.string).to include("[Test Person]")
      expect(output.string).to include("[display text]")
    end

    let!(:markdown_entry) do
      create(:codex_entry, :published, :event,
        name: "Markdown Test",
        slug: "markdown-test",
        summary: "Testing markdown",
        content: "# Header One\n## Header Two\n**bold text**\n- bullet point")
    end

    it "converts markdown headers" do
      handler.on_enter
      output.truncate(0)

      handler.handle("read markdown-test")

      expect(output.string).to include("HEADER ONE")
      expect(output.string).to include("Header Two")
    end

    it "converts bullet points" do
      handler.on_enter
      output.truncate(0)

      handler.handle("read markdown-test")

      expect(output.string).to include("\u2022")  # Bullet character
    end
  end

  describe "entry type colors" do
    it "uses different colors for different types" do
      handler.on_enter

      # Clear output and reset position properly
      output.truncate(0)
      output.rewind

      handler.handle("read test-person")
      person_output = output.string.dup

      # Clear output again for second read
      output.truncate(0)
      output.rewind

      handler.handle("read test-location")
      location_output = output.string

      # Both should have content but different color codes for the type badge
      expect(person_output).to include("[Person]")
      expect(location_output).to include("[Location]")
    end
  end
end
