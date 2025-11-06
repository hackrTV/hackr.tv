require "rails_helper"

RSpec.describe Redirect, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      redirect = build(:redirect)
      expect(redirect).to be_valid
    end

    it "is invalid without destination_url" do
      redirect = build(:redirect, destination_url: nil)
      expect(redirect).not_to be_valid
      expect(redirect.errors[:destination_url]).to include("can't be blank")
    end

    it "is invalid without path" do
      redirect = build(:redirect, path: nil)
      expect(redirect).not_to be_valid
      expect(redirect.errors[:path]).to include("can't be blank")
    end

    it "requires unique path scoped to domain" do
      create(:redirect, domain: "example.com", path: "/test")
      duplicate = build(:redirect, domain: "example.com", path: "/test")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:path]).to include("has already been taken")
    end

    it "allows same path for different domains" do
      create(:redirect, domain: "example.com", path: "/test")
      different_domain = build(:redirect, domain: "different.com", path: "/test")
      expect(different_domain).to be_valid
    end

    it "allows same path for nil domain and specific domain" do
      create(:redirect, domain: nil, path: "/test")
      specific_domain = build(:redirect, domain: "example.com", path: "/test")
      expect(specific_domain).to be_valid
    end
  end

  describe ".find_for" do
    it "finds domain-specific redirect" do
      redirect = create(:redirect, domain: "example.com", path: "/test", destination_url: "https://specific.com")
      result = Redirect.find_for("example.com", "/test")
      expect(result).to eq(redirect)
    end

    it "finds global redirect (nil domain)" do
      redirect = create(:redirect, domain: nil, path: "/test", destination_url: "https://global.com")
      result = Redirect.find_for("example.com", "/test")
      expect(result).to eq(redirect)
    end

    it "prefers domain-specific over global redirect" do
      create(:redirect, domain: nil, path: "/test", destination_url: "https://global.com")
      specific = create(:redirect, domain: "example.com", path: "/test", destination_url: "https://specific.com")

      result = Redirect.find_for("example.com", "/test")
      expect(result).to eq(specific)
      expect(result.destination_url).to eq("https://specific.com")
    end

    it "returns nil when no redirect found" do
      result = Redirect.find_for("example.com", "/nonexistent")
      expect(result).to be_nil
    end

    it "returns nil when path doesn't match" do
      create(:redirect, domain: "example.com", path: "/test")
      result = Redirect.find_for("example.com", "/other")
      expect(result).to be_nil
    end

    it "finds global redirect when domain doesn't have specific redirect" do
      global = create(:redirect, domain: nil, path: "/test", destination_url: "https://global.com")
      create(:redirect, domain: "other.com", path: "/test")

      result = Redirect.find_for("example.com", "/test")
      expect(result).to eq(global)
    end
  end

  describe "redirect scenarios" do
    it "handles ashlinn redirect" do
      redirect = create(:redirect, :ashlinn)
      result = Redirect.find_for("ashlinn.net", "/")
      expect(result).to eq(redirect)
      expect(result.destination_url).to eq("https://youtube.com/AshlinnSnow")
    end

    it "handles xeraen redirect" do
      redirect = create(:redirect, :xeraen)
      result = Redirect.find_for("xeraen.com", "/")
      expect(result).to eq(redirect)
      expect(result.destination_url).to eq("/xeraen")
    end

    it "handles multiple paths for same domain" do
      redirect1 = create(:redirect, domain: "xeraen.com", path: "/", destination_url: "/xeraen")
      redirect2 = create(:redirect, domain: "xeraen.com", path: "/git", destination_url: "https://github.com/xeraen")

      expect(Redirect.find_for("xeraen.com", "/")).to eq(redirect1)
      expect(Redirect.find_for("xeraen.com", "/git")).to eq(redirect2)
    end
  end

  describe "full redirect lifecycle" do
    it "creates and updates redirects" do
      redirect = Redirect.create!(
        domain: "test.com",
        path: "/old-path",
        destination_url: "https://new.com"
      )

      expect(redirect).to be_persisted
      expect(redirect.domain).to eq("test.com")

      redirect.update!(destination_url: "https://updated.com")
      expect(redirect.reload.destination_url).to eq("https://updated.com")
    end
  end
end
