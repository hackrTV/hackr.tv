# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::GridWorldExportController, type: :controller do
  let(:admin_hackr) { create(:grid_hackr, :admin) }

  before { session[:grid_hackr_id] = admin_hackr.id }

  describe "GET #download" do
    it "returns a gzipped tar file" do
      get :download
      expect(response).to have_http_status(:ok)
      expect(response.headers["Content-Type"]).to eq("application/gzip")
      expect(response.headers["Content-Disposition"]).to include("world-export-")
      expect(response.headers["Content-Disposition"]).to include(".tar.gz")
    end

    it "contains valid gzip data" do
      get :download
      bytes = response.body.bytes
      expect(bytes[0..1]).to eq([0x1f, 0x8b])
    end

    it "requires admin" do
      session[:grid_hackr_id] = nil
      get :download
      expect(response).to have_http_status(:redirect)
    end
  end
end
