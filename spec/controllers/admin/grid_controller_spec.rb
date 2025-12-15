require "rails_helper"

RSpec.describe Admin::GridController, type: :controller do
  let(:admin_hackr) { create(:grid_hackr, :admin) }
  let(:regular_hackr) { create(:grid_hackr, role: "operative") }

  describe "GET #index" do
    before do
      session[:grid_hackr_id] = admin_hackr.id
    end

    it "returns success" do
      get :index
      expect(response).to have_http_status(:ok)
    end

    it "loads online hackrs" do
      online_hackr = create(:grid_hackr, :online)
      get :index
      expect(assigns(:online_hackrs)).to include(online_hackr)
    end

    it "loads recent messages" do
      room = create(:grid_room)
      message = create(:grid_message, room: room, grid_hackr: admin_hackr)
      get :index
      expect(assigns(:recent_messages)).to include(message)
    end

    it "loads all hackrs" do
      hackr = create(:grid_hackr)
      get :index
      expect(assigns(:all_hackrs)).to include(hackr)
    end
  end

  describe "POST #broadcast" do
    let!(:room1) { create(:grid_room) }
    let!(:room2) { create(:grid_room) }

    before do
      session[:grid_hackr_id] = admin_hackr.id
      allow(GridChannel).to receive(:broadcast_to)
    end

    it "creates system messages for all rooms" do
      expect {
        post :broadcast, params: {message: "Test broadcast"}
      }.to change(GridMessage, :count).by(GridRoom.count)
    end

    it "creates messages with system type" do
      post :broadcast, params: {message: "Test broadcast"}

      messages = GridMessage.where(message_type: "system")
      expect(messages.count).to eq(GridRoom.count)
    end

    it "includes broadcast prefix in message content" do
      post :broadcast, params: {message: "Hello everyone"}

      message = GridMessage.last
      expect(message.content).to eq("[SYSTEM BROADCAST] Hello everyone")
    end

    it "broadcasts to all rooms via GridChannel" do
      post :broadcast, params: {message: "Test broadcast"}

      GridRoom.find_each do |room|
        expect(GridChannel).to have_received(:broadcast_to).with(
          room,
          hash_including(
            type: "system_broadcast",
            message: "[SYSTEM BROADCAST] Test broadcast",
            sender: admin_hackr.hackr_alias
          )
        )
      end
    end

    it "redirects to admin grid path" do
      post :broadcast, params: {message: "Test"}
      expect(response).to redirect_to(admin_grid_path)
    end

    it "sets success flash" do
      post :broadcast, params: {message: "Test"}
      expect(flash[:success]).to include("Broadcast sent")
    end

    context "with empty message" do
      it "does not create messages" do
        expect {
          post :broadcast, params: {message: ""}
        }.not_to change(GridMessage, :count)
      end

      it "does not broadcast" do
        post :broadcast, params: {message: "   "}
        expect(GridChannel).not_to have_received(:broadcast_to)
      end

      it "sets error flash" do
        post :broadcast, params: {message: ""}
        expect(flash[:error]).to include("empty")
      end

      it "redirects to admin grid path" do
        post :broadcast, params: {message: ""}
        expect(response).to redirect_to(admin_grid_path)
      end
    end
  end

  describe "authentication" do
    before do
      session[:grid_hackr_id] = nil
    end

    it "redirects unauthenticated users to grid" do
      get :index
      expect(response).to redirect_to(grid_path)
    end

    it "redirects regular users to grid" do
      session[:grid_hackr_id] = regular_hackr.id

      get :index
      expect(response).to redirect_to(grid_path)
    end

    it "sets error flash for non-admin users" do
      session[:grid_hackr_id] = regular_hackr.id

      get :index
      expect(flash[:error]).to include("Admin privileges required")
    end

    it "prevents regular users from broadcasting" do
      session[:grid_hackr_id] = regular_hackr.id

      post :broadcast, params: {message: "Hacked!"}
      expect(response).to redirect_to(grid_path)
    end

    it "does not create messages when non-admin tries to broadcast" do
      session[:grid_hackr_id] = regular_hackr.id

      expect {
        post :broadcast, params: {message: "Hacked!"}
      }.not_to change(GridMessage, :count)
    end
  end
end
