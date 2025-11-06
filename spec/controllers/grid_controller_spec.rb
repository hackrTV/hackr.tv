require "rails_helper"

RSpec.describe GridController, type: :controller do
  let(:zone) { create(:grid_zone) }
  let(:room) { create(:grid_room, grid_zone: zone, room_type: "hub") }
  let(:hackr) { create(:grid_hackr, current_room: room) }
  let(:admin) { create(:grid_hackr, :admin, current_room: room) }

  describe "GET #index" do
    context "when logged in" do
      before { session[:grid_hackr_id] = hackr.id }

      it "returns http success" do
        get :index
        expect(response).to have_http_status(:success)
      end

      it "assigns @current_room" do
        get :index
        expect(assigns(:current_room)).to eq(room)
      end

      it "loads recent messages" do
        message = create(:grid_message, grid_hackr: hackr, room: room)
        get :index
        expect(assigns(:messages)).to include(message)
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        get :index
        expect(response).to redirect_to(grid_login_path)
      end
    end
  end

  describe "GET #login" do
    context "when not logged in" do
      it "returns http success" do
        get :login
        expect(response).to have_http_status(:success)
      end
    end

    context "when already logged in" do
      before { session[:grid_hackr_id] = hackr.id }

      it "redirects to grid path" do
        get :login
        expect(response).to redirect_to(grid_path)
      end
    end
  end

  describe "POST #create_session" do
    let(:valid_credentials) do
      {hackr_alias: hackr.hackr_alias, password: "password123"}
    end

    let(:invalid_credentials) do
      {hackr_alias: hackr.hackr_alias, password: "wrongpassword"}
    end

    context "with valid credentials" do
      it "logs in the hackr" do
        post :create_session, params: valid_credentials
        expect(session[:grid_hackr_id]).to eq(hackr.id)
      end

      it "redirects to grid path" do
        post :create_session, params: valid_credentials
        expect(response).to redirect_to(grid_path)
      end

      it "sets a success flash message" do
        post :create_session, params: valid_credentials
        expect(flash[:success]).to match(/Welcome back/)
      end
    end

    context "with invalid credentials" do
      it "does not log in" do
        post :create_session, params: invalid_credentials
        expect(session[:grid_hackr_id]).to be_nil
      end

      it "renders login page" do
        post :create_session, params: invalid_credentials
        expect(response).to render_template(:login)
      end

      it "returns unprocessable entity status" do
        post :create_session, params: invalid_credentials
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "sets an error flash message" do
        post :create_session, params: invalid_credentials
        expect(flash[:error]).to match(/Invalid/)
      end
    end

    context "with non-existent hackr" do
      it "does not log in" do
        post :create_session, params: {hackr_alias: "NonExistent", password: "anything"}
        expect(session[:grid_hackr_id]).to be_nil
      end
    end
  end

  describe "GET #register" do
    context "when not logged in" do
      it "returns http success" do
        get :register
        expect(response).to have_http_status(:success)
      end
    end

    context "when already logged in" do
      before { session[:grid_hackr_id] = hackr.id }

      it "redirects to grid path" do
        get :register
        expect(response).to redirect_to(grid_path)
      end
    end
  end

  describe "POST #create_hackr" do
    let(:hub_zone) { create(:grid_zone, slug: "hackr_tv_central") }
    let(:hub_room) { create(:grid_room, grid_zone: hub_zone, room_type: "hub") }

    let(:valid_params) do
      {
        grid_hackr: {
          hackr_alias: "NewHackr",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    let(:invalid_params) do
      {
        grid_hackr: {
          hackr_alias: "",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    before { hub_room } # Ensure starting room exists

    context "with valid params" do
      it "creates a new hackr" do
        expect {
          post :create_hackr, params: valid_params
        }.to change(GridHackr, :count).by(1)
      end

      it "logs in the new hackr" do
        post :create_hackr, params: valid_params
        expect(session[:grid_hackr_id]).to eq(GridHackr.last.id)
      end

      it "sets the starting room" do
        post :create_hackr, params: valid_params
        expect(GridHackr.last.current_room).to eq(hub_room)
      end

      it "redirects to grid path" do
        post :create_hackr, params: valid_params
        expect(response).to redirect_to(grid_path)
      end

      it "sets a success flash message" do
        post :create_hackr, params: valid_params
        expect(flash[:success]).to match(/Welcome to THE PULSE GRID/)
      end
    end

    context "with invalid params" do
      it "does not create a hackr" do
        expect {
          post :create_hackr, params: invalid_params
        }.not_to change(GridHackr, :count)
      end

      it "renders register page" do
        post :create_hackr, params: invalid_params
        expect(response).to render_template(:register)
      end

      it "returns unprocessable entity status" do
        post :create_hackr, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "sets an error flash message" do
        post :create_hackr, params: invalid_params
        expect(flash[:error]).to match(/Registration failed/)
      end
    end

    context "with mismatched password confirmation" do
      let(:mismatched_params) do
        {
          grid_hackr: {
            hackr_alias: "NewHackr",
            password: "password123",
            password_confirmation: "different"
          }
        }
      end

      it "does not create a hackr" do
        expect {
          post :create_hackr, params: mismatched_params
        }.not_to change(GridHackr, :count)
      end
    end
  end

  describe "DELETE #logout" do
    before { session[:grid_hackr_id] = hackr.id }

    it "logs out the hackr" do
      delete :logout
      expect(session[:grid_hackr_id]).to be_nil
    end

    it "redirects to login page" do
      delete :logout
      expect(response).to redirect_to(grid_login_path)
    end

    it "sets a notice flash message" do
      delete :logout
      expect(flash[:notice]).to match(/disconnected/)
    end
  end

  describe "POST #command" do
    before { session[:grid_hackr_id] = hackr.id }

    context "with JSON format" do
      it "executes the command" do
        post :command, params: {input: "look"}, format: :json
        expect(response).to have_http_status(:success)
      end

      it "returns the command output" do
        post :command, params: {input: "look"}, format: :json
        json = JSON.parse(response.body)
        expect(json["output"]).to be_present
        expect(json["success"]).to be true
      end
    end

    context "with HTML format" do
      it "renders the index template" do
        post :command, params: {input: "look"}
        expect(response).to render_template(:index)
      end

      it "sets flash with command output" do
        post :command, params: {input: "look"}
        expect(flash[:command_output]).to be_present
      end
    end

    context "when not logged in" do
      before { session.delete(:grid_hackr_id) }

      it "redirects to login" do
        post :command, params: {input: "look"}
        expect(response).to redirect_to(grid_login_path)
      end
    end
  end
end
