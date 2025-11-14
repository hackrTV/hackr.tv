require "rails_helper"

RSpec.describe "layouts/fm", type: :view do
  before do
    # Define authentication helpers
    def view.logged_in?
      false
    end

    def view.admin_hackr?
      false
    end

    # Stub the Vite helper methods
    allow(view).to receive(:vite_client_tag).and_return('<script type="module" src="/@vite/client"></script>'.html_safe)
    allow(view).to receive(:vite_typescript_tag).and_return('<script type="module" src="/vite-dev/assets/application.tsx"></script>'.html_safe)
    allow(view).to receive(:vite_javascript_tag).and_return('<script type="module" src="/vite-dev/assets/application.js"></script>'.html_safe)
  end

  it "includes Vite client tag for HMR" do
    render template: "layouts/fm", layout: "layouts/application"

    expect(rendered).to include("/@vite/client")
  end

  it "includes React application entrypoint" do
    render template: "layouts/fm", layout: "layouts/application"

    expect(rendered).to include("/vite-dev/assets/application.tsx")
  end

  it "includes React audio player mount point" do
    render template: "layouts/fm", layout: "layouts/application"

    expect(rendered).to include('<div id="react-audio-player-root"></div>')
  end

  it "includes audio_player.js for vanilla JS bridge" do
    render template: "layouts/fm", layout: "layouts/application"

    expect(rendered).to include("audio_player")
  end
end
