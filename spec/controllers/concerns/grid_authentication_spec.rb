require "rails_helper"

RSpec.describe GridAuthentication, type: :controller do
  # Create a test controller to test the concern
  controller(ApplicationController) do
    include GridAuthentication

    before_action :require_admin, only: [:admin_only]
    before_action :require_login, only: [:login_required]
    before_action :require_logout, only: [:logout_required]

    def index
      render plain: "index"
    end

    def admin_only
      render plain: "admin area"
    end

    def login_required
      render plain: "protected"
    end

    def logout_required
      render plain: "logout page"
    end
  end

  before do
    routes.draw {
      get "index" => "anonymous#index"
      get "admin_only" => "anonymous#admin_only"
      get "login_required" => "anonymous#login_required"
      get "logout_required" => "anonymous#logout_required"
      get "grid_login" => "anonymous#index", :as => :grid_login
      get "grid" => "anonymous#index", :as => :grid
    }
  end

  let(:operative) { create(:grid_hackr, role: "operative") }
  let(:admin) { create(:grid_hackr, role: "admin") }

  describe "#current_hackr" do
    context "when hackr is logged in via session" do
      before { session[:grid_hackr_id] = operative.id }

      it "returns the current hackr" do
        expect(controller.send(:current_hackr)).to eq(operative)
      end
    end

    context "when hackr authenticates via Bearer token" do
      before do
        operative.generate_api_token!
        request.headers["Authorization"] = "Bearer #{operative.api_token}"
      end

      it "returns the hackr associated with the token" do
        expect(controller.send(:current_hackr)).to eq(operative)
      end
    end

    context "when both session and token are present" do
      before do
        session[:grid_hackr_id] = admin.id
        operative.generate_api_token!
        request.headers["Authorization"] = "Bearer #{operative.api_token}"
      end

      it "prefers token authentication over session" do
        expect(controller.send(:current_hackr)).to eq(operative)
      end
    end

    context "when invalid token is provided" do
      before do
        request.headers["Authorization"] = "Bearer invalid_token"
      end

      it "returns nil" do
        expect(controller.send(:current_hackr)).to be_nil
      end
    end

    context "when no hackr is logged in" do
      it "returns nil" do
        expect(controller.send(:current_hackr)).to be_nil
      end
    end
  end

  describe "#api_token_request?" do
    context "when Authorization header has Bearer token" do
      before do
        request.headers["Authorization"] = "Bearer some_token"
      end

      it "returns true" do
        expect(controller.send(:api_token_request?)).to be true
      end
    end

    context "when Authorization header is missing" do
      it "returns falsey" do
        expect(controller.send(:api_token_request?)).to be_falsey
      end
    end

    context "when Authorization header has different auth type" do
      before do
        request.headers["Authorization"] = "Basic some_credentials"
      end

      it "returns false" do
        expect(controller.send(:api_token_request?)).to be false
      end
    end
  end

  describe "#logged_in?" do
    context "when hackr is logged in" do
      before { session[:grid_hackr_id] = operative.id }

      it "returns true" do
        expect(controller.send(:logged_in?)).to be true
      end
    end

    context "when no hackr is logged in" do
      it "returns false" do
        expect(controller.send(:logged_in?)).to be false
      end
    end
  end

  describe "#admin_hackr?" do
    context "when admin is logged in" do
      before { session[:grid_hackr_id] = admin.id }

      it "returns true" do
        expect(controller.send(:admin_hackr?)).to be true
      end
    end

    context "when operative is logged in" do
      before { session[:grid_hackr_id] = operative.id }

      it "returns false" do
        expect(controller.send(:admin_hackr?)).to be false
      end
    end

    context "when no hackr is logged in" do
      it "returns false" do
        expect(controller.send(:admin_hackr?)).to be false
      end
    end
  end

  describe "#log_in" do
    it "sets the session hackr_id" do
      controller.send(:log_in, operative)
      expect(session[:grid_hackr_id]).to eq(operative.id)
    end

    it "sets the @current_hackr instance variable" do
      controller.send(:log_in, operative)
      expect(controller.instance_variable_get(:@current_hackr)).to eq(operative)
    end
  end

  describe "#log_out" do
    before do
      session[:grid_hackr_id] = operative.id
      controller.instance_variable_set(:@current_hackr, operative)
    end

    it "removes the session hackr_id" do
      controller.send(:log_out)
      expect(session[:grid_hackr_id]).to be_nil
    end

    it "clears the @current_hackr instance variable" do
      controller.send(:log_out)
      expect(controller.instance_variable_get(:@current_hackr)).to be_nil
    end
  end

  describe "#require_login" do
    context "when hackr is logged in" do
      before { session[:grid_hackr_id] = operative.id }

      it "allows access" do
        get :login_required
        expect(response.body).to eq("protected")
      end
    end

    context "when no hackr is logged in" do
      it "redirects to login page" do
        get :login_required
        expect(response).to redirect_to(grid_login_path)
      end

      it "sets an error flash message" do
        get :login_required
        expect(flash[:error]).to eq("Access denied. Please log in to THE PULSE GRID.")
      end
    end
  end

  describe "#require_admin" do
    context "when admin is logged in" do
      before { session[:grid_hackr_id] = admin.id }

      it "allows access" do
        get :admin_only
        expect(response.body).to eq("admin area")
      end
    end

    context "when operative is logged in" do
      before { session[:grid_hackr_id] = operative.id }

      it "redirects to grid path" do
        get :admin_only
        expect(response).to redirect_to(grid_path)
      end

      it "sets an error flash message" do
        get :admin_only
        expect(flash[:error]).to eq("Access denied. Admin privileges required.")
      end
    end

    context "when no hackr is logged in" do
      it "redirects to grid path" do
        get :admin_only
        expect(response).to redirect_to(grid_path)
      end
    end
  end

  describe "#require_logout" do
    context "when hackr is logged in" do
      before { session[:grid_hackr_id] = operative.id }

      it "redirects to grid path" do
        get :logout_required
        expect(response).to redirect_to(grid_path)
      end

      it "sets a notice flash message" do
        get :logout_required
        expect(flash[:notice]).to eq("You are already logged into THE PULSE GRID.")
      end
    end

    context "when no hackr is logged in" do
      it "allows access" do
        get :logout_required
        expect(response.body).to eq("logout page")
      end
    end
  end
end
