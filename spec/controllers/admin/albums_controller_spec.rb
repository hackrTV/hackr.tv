require "rails_helper"

RSpec.describe Admin::AlbumsController, type: :controller do
  let(:admin_hackr) { create(:grid_hackr, role: "admin") }
  let(:artist) { create(:artist) }

  before do
    session[:grid_hackr_id] = admin_hackr.id
  end

  describe "GET #index" do
    it "returns success" do
      get :index
      expect(response).to have_http_status(:ok)
    end

    it "loads albums with artists" do
      album = create(:album, artist: artist)

      get :index

      expect(assigns(:albums)).to include(album)
    end

    it "orders albums by artist name then release date" do
      artist_z = create(:artist, name: "Zebra")
      artist_a = create(:artist, name: "Alpha")

      create(:album, artist: artist_z, release_date: Date.today)
      album_a = create(:album, artist: artist_a, release_date: Date.today)

      get :index

      expect(assigns(:albums).to_a.first).to eq(album_a)
    end
  end

  describe "GET #new" do
    it "returns success" do
      get :new
      expect(response).to have_http_status(:ok)
    end

    it "builds a new album" do
      get :new
      expect(assigns(:album)).to be_a_new(Album)
    end

    it "loads artists for dropdown" do
      artist

      get :new

      expect(assigns(:artists)).to include(artist)
    end
  end

  describe "POST #create" do
    let(:valid_params) do
      {
        album: {
          name: "New Album",
          slug: "new-album",
          artist_id: artist.id,
          album_type: "studio",
          release_date: Date.today,
          description: "Test description"
        }
      }
    end

    it "creates a new album" do
      expect {
        post :create, params: valid_params
      }.to change(Album, :count).by(1)
    end

    it "redirects to index on success" do
      post :create, params: valid_params
      expect(response).to redirect_to(admin_albums_path)
    end

    it "sets success flash message" do
      post :create, params: valid_params
      expect(flash[:success]).to include("New Album")
    end

    it "renders new template on failure" do
      invalid_params = {album: {name: "", artist_id: artist.id}}
      post :create, params: invalid_params
      expect(response).to have_http_status(:unprocessable_content)
      expect(response).to render_template(:new)
    end

    it "loads artists on failure for dropdown" do
      invalid_params = {album: {name: ""}}
      post :create, params: invalid_params
      expect(assigns(:artists)).to include(artist)
    end
  end

  describe "GET #edit" do
    let(:album) { create(:album, artist: artist) }

    it "returns success" do
      get :edit, params: {id: album.id}
      expect(response).to have_http_status(:ok)
    end

    it "loads the correct album by ID" do
      get :edit, params: {id: album.id}
      expect(assigns(:album)).to eq(album)
    end

    it "loads artists for dropdown" do
      get :edit, params: {id: album.id}
      expect(assigns(:artists)).to include(artist)
    end
  end

  describe "PATCH #update" do
    let(:album) { create(:album, artist: artist, name: "Old Name") }

    it "updates the album" do
      patch :update, params: {
        id: album.id,
        album: {name: "New Name"}
      }

      album.reload
      expect(album.name).to eq("New Name")
    end

    it "redirects to index on success" do
      patch :update, params: {
        id: album.id,
        album: {name: "New Name"}
      }

      expect(response).to redirect_to(admin_albums_path)
    end

    it "sets success flash message" do
      patch :update, params: {
        id: album.id,
        album: {name: "New Name"}
      }

      expect(flash[:success]).to include("New Name")
    end

    it "renders edit template on failure" do
      patch :update, params: {
        id: album.id,
        album: {name: ""}
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response).to render_template(:edit)
    end

    it "loads artists on failure for dropdown" do
      patch :update, params: {
        id: album.id,
        album: {name: ""}
      }

      expect(assigns(:artists)).to include(artist)
    end
  end

  describe "DELETE #destroy" do
    let!(:album) { create(:album, artist: artist) }

    it "destroys the album" do
      expect {
        delete :destroy, params: {id: album.id}
      }.to change(Album, :count).by(-1)
    end

    it "redirects to index" do
      delete :destroy, params: {id: album.id}
      expect(response).to redirect_to(admin_albums_path)
    end

    it "sets success flash message" do
      name = album.name
      delete :destroy, params: {id: album.id}
      expect(flash[:success]).to include(name)
    end

    context "when album has tracks" do
      before do
        create(:track, album: album, artist: artist)
      end

      it "does not destroy the album" do
        expect {
          delete :destroy, params: {id: album.id}
        }.not_to change(Album, :count)
      end

      it "sets error flash message" do
        delete :destroy, params: {id: album.id}
        expect(flash[:error]).to include("Cannot delete")
      end
    end
  end

  describe "cover image handling" do
    let(:album) { create(:album, artist: artist) }

    it "removes cover image when requested" do
      # Attach a cover image first
      album.cover_image.attach(
        io: StringIO.new("fake image data"),
        filename: "cover.jpg",
        content_type: "image/jpeg"
      )

      expect(album.cover_image).to be_attached

      patch :update, params: {
        id: album.id,
        album: {remove_cover_image: "1", name: album.name}
      }

      album.reload
      expect(album.cover_image).not_to be_attached
    end
  end

  describe "authentication" do
    before do
      session[:grid_hackr_id] = nil
    end

    it "redirects non-admin users to grid" do
      get :index
      expect(response).to redirect_to(grid_path)
    end

    it "redirects regular users to grid" do
      regular_user = create(:grid_hackr, role: "operative")
      session[:grid_hackr_id] = regular_user.id

      get :index
      expect(response).to redirect_to(grid_path)
    end
  end
end
