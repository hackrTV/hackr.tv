require "rails_helper"

# Mirrors the SPA's BioText.test.tsx cases (Hotwire migration Phase 3).
RSpec.describe BioTextRenderer do
  def render(text) = described_class.render(text)

  it "passes plain text through unchanged" do
    expect(render("Just a ghost in the wire.")).to eq("Just a ghost in the wire.")
  end

  it "links an @mention to the wire profile" do
    html = render("shouting out @xeraen today")

    expect(html).to include('<a href="/wire/xeraen"')
    expect(html).to include(">@xeraen</a>")
  end

  it "does not linkify external URLs" do
    html = render("visit https://evil.example.com now")

    expect(html).not_to include("<a")
    expect(html).to include("https://evil.example.com")
  end

  it "does not link email local parts" do
    html = render("reach me at me@gmail.com anytime")

    expect(html).not_to include("<a")
    expect(html).to include("me@gmail.com")
  end

  it "links only word-boundary mentions" do
    html = render("email me@host but ping @xeraen")

    expect(html.scan("<a ").length).to eq(1)
    expect(html).to include('<a href="/wire/xeraen"')
    expect(html).to include("me@host")
  end

  it "links a mention at the start of the bio" do
    html = render("@xeraen runs this place")

    expect(html).to include('<a href="/wire/xeraen"')
  end

  it "escapes HTML" do
    html = render("<b>bold</b> @xeraen")

    expect(html).to include("&lt;b&gt;")
    expect(html).to include('<a href="/wire/xeraen"')
  end

  it "returns empty for blank text" do
    expect(render(nil)).to eq("")
  end
end
