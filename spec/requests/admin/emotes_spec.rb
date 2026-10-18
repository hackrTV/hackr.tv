require "rails_helper"

# /root/emotes — admin CRUD for chat emotes (slug-keyed, Active Storage
# image, PaperTrail history).
RSpec.describe "Admin emotes", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  def upload(name, type)
    Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files", name), type)
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/emotes"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists emotes with previews, tokens and status" do
    create(:emote, slug: "wave")
    create(:emote, :disabled, slug: "off")
    log_in!(admin)

    get "/root/emotes"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(":wave:")
    expect(response.body).to include(":off:")
    expect(response.body).to include("ENABLED")
    expect(response.body).to include("DISABLED")
    expect(response.body).to include("/rails/active_storage/representations/redirect/")
  end

  it "creates an emote from an upload, normalizes the slug, and redirects to edit" do
    log_in!(admin)

    expect {
      post "/root/emotes", params: {emote: {slug: "Wave", enabled: "1", image: upload("test_emote.png", "image/png")}}
    }.to change(Emote, :count).by(1)

    emote = Emote.last
    expect(emote.slug).to eq("wave")
    expect(emote.image).to be_attached
    expect(response).to redirect_to("/root/emotes/wave/edit")
    follow_redirect!
    expect(response.body).to include("Emote :wave: created.")
  end

  it "re-renders the form with errors for a rejected upload" do
    log_in!(admin)

    post "/root/emotes", params: {emote: {slug: "cover", image: upload("test_cover.jpg", "image/jpeg")}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("must be a PNG, GIF, or WebP image")
    expect(Emote.count).to eq(0)
  end

  it "requires an image on create" do
    log_in!(admin)

    post "/root/emotes", params: {emote: {slug: "ghost"}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("Image can")
    expect(Emote.count).to eq(0)
  end

  it "updates slug and enabled without touching the image, following the new slug" do
    emote = create(:emote, slug: "wave")
    log_in!(admin)

    patch "/root/emotes/wave", params: {emote: {slug: "wave2", enabled: "0"}}

    expect(response).to redirect_to("/root/emotes/wave2/edit")
    emote.reload
    expect(emote.slug).to eq("wave2")
    expect(emote.enabled).to be(false)
    expect(emote.image).to be_attached
  end

  it "purges the image without deleting the emote (and drops it from the render map)" do
    emote = create(:emote, slug: "wave")
    log_in!(admin)

    delete "/root/emotes/wave/purge_image"

    expect(response).to redirect_to("/root/emotes/wave/edit")
    expect(emote.reload.image).not_to be_attached
    expect(Emote.render_map).to eq({})
  end

  it "re-renders edit against the saved slug when the new slug is invalid" do
    create(:emote, slug: "wave")
    log_in!(admin)

    patch "/root/emotes/wave", params: {emote: {slug: "Bad Slug"}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("may only contain a-z, 0-9 and _")
    expect(response.body).to include('action="/root/emotes/wave"') # not /root/emotes/bad slug
    expect(response.body).to include("/root/emotes/wave/history")
    expect(Emote.find_by(slug: "wave")).to be_present
  end

  it "re-renders edit without a 500 when a replacement upload is rejected" do
    create(:emote, slug: "wave")
    log_in!(admin)

    patch "/root/emotes/wave", params: {emote: {image: upload("test_cover.jpg", "image/jpeg")}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("must be a PNG, GIF, or WebP image")
    expect(response.body).to include("Upload rejected")
    expect(Emote.find_by(slug: "wave").image.content_type).to eq("image/png") # untouched
  end

  it "destroys an emote" do
    create(:emote, slug: "wave")
    log_in!(admin)

    expect { delete "/root/emotes/wave" }.to change(Emote, :count).by(-1)
    expect(response).to redirect_to("/root/emotes")
  end

  it "renders the PaperTrail history page" do
    create(:emote, slug: "wave").update!(enabled: false)
    log_in!(admin)

    get "/root/emotes/wave/history"

    expect(response).to have_http_status(:ok)
  end
end
