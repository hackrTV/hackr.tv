require "rails_helper"

# ConsoleFormBuilder — the /root console's rc_* field rows (the admin's
# default builder; console-ui-for-all-admin Phase 0, 2026-10-30). Each
# helper's markup is pinned against the idiom the music _forms hand-wrote.
RSpec.describe ConsoleFormBuilder do
  let(:template) do
    ActionView::Base.empty.tap do |t|
      t.extend(ActionView::Helpers::FormHelper)
      t.extend(ActionView::Helpers::FormOptionsHelper)
    end
  end
  let(:artist) { Artist.new(name: "XERAEN", slug: "xeraen") }
  let(:builder) { described_class.new(:artist, artist, template, {}) }

  describe "field rows" do
    it "renders the status row: a console-key label for the input, the rc-input in the value cell" do
      html = Capybara.string(builder.rc_text_field(:name, required: true, autocomplete: "off"))
      expect(html).to have_css("div.console-status-row.rc-field > label.console-key[for='artist_name']", text: "NAME")
      expect(html).to have_css("div.rc-field > span.console-val > input.rc-input[name='artist[name]'][value='XERAEN'][required][autocomplete='off']")
      expect(html).not_to have_css(".rc-hint")
      expect(html).not_to have_css(".rc-err")
    end

    it "takes a label, a width and extra classes" do
      html = Capybara.string(builder.rc_text_field(:slug, label: "CATALOG #", width: :short, class: "extra"))
      expect(html).to have_css("label.console-key", text: "CATALOG #")
      expect(html).to have_css("input.rc-input.rc-input--short.extra")
    end

    it "gives date fields the date width and datetime fields the wider datetime width by default" do
      html = Capybara.string(builder.rc_date_field(:created_at))
      expect(html).to have_css("label.console-key", text: "CREATED AT")
      expect(html).to have_css("input.rc-input.rc-input--date[type='date']")
      expect(Capybara.string(builder.rc_datetime_local_field(:created_at))).to have_css("input.rc-input.rc-input--datetime[type='datetime-local']")
      expect(Capybara.string(builder.rc_time_field(:created_at))).to have_css("input.rc-input[type='time']:not([class*='rc-input--'])")
    end

    it "renders a hint after the input, markup kept when it is safe" do
      html = Capybara.string(builder.rc_text_field(:slug, hint: "lowercase · hyphens"))
      expect(html).to have_css("span.console-val > input.rc-input + span.rc-hint", text: "lowercase · hyphens")
      safe = Capybara.string(builder.rc_text_field(:slug, hint: template.safe_join(["see ", template.tag.a("the catalog", href: "/x")])))
      expect(safe).to have_css("span.rc-hint a[href='/x']", text: "the catalog")
    end

    it "renders the inline error last" do
      artist.errors.add(:name, "can't be blank")
      html = Capybara.string(builder.rc_text_field(:name, hint: "h"))
      expect(html).to have_css("span.rc-hint + span.rc-err", text: "can't be blank")
    end

    it "offers every input type of the idiom" do
      %i[rc_text_field rc_number_field rc_password_field rc_email_field rc_url_field rc_date_field
        rc_datetime_local_field rc_time_field rc_color_field rc_file_field].each do |helper|
        expect(builder).to respond_to(helper)
      end
      expect(Capybara.string(builder.rc_number_field(:name, min: 1))).to have_css("input.rc-input[type='number'][min='1']")
      expect(Capybara.string(builder.rc_file_field(:name))).to have_css("span.console-val > input.rc-input[type='file']")
    end
  end

  describe "#rc_select" do
    it "renders the rc-select with its options and html options" do
      html = Capybara.string(builder.rc_select(:artist_type, [%w[BAND band], %w[OST ost]], {include_blank: "—"}, required: true, hint: "the directory"))
      expect(html).to have_css("div.rc-field > label.console-key[for='artist_artist_type']", text: "ARTIST TYPE")
      expect(html).to have_css("span.console-val > select.rc-select[name='artist[artist_type]'][required]")
      expect(html).to have_css("option[value='']", text: "—")
      expect(html).to have_css("option[value='ost']", text: "OST")
      expect(html).to have_css("select + span.rc-hint", text: "the directory")
    end

    it "takes include_blank / prompt as keywords too, never as select attributes" do
      html = Capybara.string(builder.rc_select(:artist_type, [%w[BAND band]], include_blank: "—", required: true))
      expect(html).to have_css("select.rc-select[required]:not([include_blank])")
      expect(html).to have_css("option[value='']", text: "—")
      prompt = Capybara.string(builder.rc_collection_select(:genre, [], :id, :name, prompt: "pick one")) # genre is blank, so the prompt shows
      expect(prompt).to have_css("select.rc-select:not([prompt]) option[value='']", text: "pick one")
    end

    it "labels a *_id select by the association and shows the association's error" do
      release = Release.new
      release.errors.add(:artist, "must exist")
      html = Capybara.string(described_class.new(:release, release, template, {}).rc_select(:artist_id, [["XERAEN", 1]]))
      expect(html).to have_css("label.console-key[for='release_artist_id']", text: "ARTIST")
      expect(html).to have_css("span.rc-err", text: "must exist")
    end
  end

  describe "#rc_collection_select" do
    it "renders the rc-select from a collection" do
      option = Struct.new(:id, :name)
      html = Capybara.string(builder.rc_collection_select(:artist_type, [option.new("ost", "Soundtrack")], :id, :name, {include_blank: true}, label: "TYPE"))
      expect(html).to have_css("label.console-key", text: "TYPE")
      expect(html).to have_css("select.rc-select option[value='ost']", text: "Soundtrack")
    end
  end

  describe "#rc_check_box and #rc_flags" do
    it "renders the inline rc-check label wrapping the box, no row of its own" do
      html = Capybara.string(builder.rc_check_box(:name, label: "★ FEATURED"))
      expect(html).to have_css("label.rc-check > input[type='checkbox'][name='artist[name]']")
      expect(html).to have_css("label.rc-check", text: "★ FEATURED")
      expect(html).not_to have_css(".rc-field")
    end

    it "groups boxes in one row keyed by the label, the hint last" do
      html = Capybara.string(builder.rc_flags("FLAGS", hint: "featured sorts first") {
        template.safe_join([builder.rc_check_box(:name, label: "A"), builder.rc_check_box(:slug, label: "B")])
      })
      expect(html).to have_css("div.console-status-row.rc-field > span.console-key", text: "FLAGS")
      expect(html).to have_css("span.console-val > label.rc-check", count: 2)
      expect(html).to have_css("span.console-val > label.rc-check + label.rc-check + span.rc-hint", text: "featured sorts first")
    end
  end

  describe "#rc_text_area" do
    it "renders the // LABEL // rule and a growing textarea" do
      html = Capybara.string(builder.rc_text_area(:name, rows: 3))
      expect(html).to have_css("div.console-rule > span", text: "// NAME //")
      expect(html).to have_css("div.console-rule + textarea.rc-textarea[name='artist[name]'][rows='3'][data-controller='autogrow'][data-action='input->autogrow#grow']", text: "XERAEN")
      expect(html).not_to have_css("p.rc-sub")
    end

    it "takes a label, extra classes, html options and a note under it; autogrow can be off" do
      html = Capybara.string(builder.rc_text_area(:name, label: "DECODED LYRICS", rows: 16, spellcheck: true, class: "rc-textarea--lyrics", hint: "markdown", autogrow: false))
      expect(html).to have_css("div.console-rule > span", text: "// DECODED LYRICS //")
      expect(html).to have_css("textarea.rc-textarea.rc-textarea--lyrics[rows='16'][spellcheck='true']")
      expect(html).not_to have_css("textarea[data-controller]")
      expect(html).to have_css("textarea + p.rc-sub", text: "markdown")
    end

    it "puts the error in the note" do
      artist.errors.add(:name, "is too long")
      html = Capybara.string(builder.rc_text_area(:name))
      expect(html).to have_css("p.rc-sub > span.rc-err", text: "is too long")
    end
  end

  it "still answers the legacy tui_* family until Phase 6 retires it" do
    expect(Capybara.string(builder.tui_text_field(:name))).to have_css("div.tui-field input.tui-input")
  end
end
