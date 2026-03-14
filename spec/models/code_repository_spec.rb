require "rails_helper"

RSpec.describe CodeRepository, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      repo = build(:code_repository)
      expect(repo).to be_valid
    end

    it "is invalid without a name" do
      repo = build(:code_repository, name: nil)
      expect(repo).not_to be_valid
      expect(repo.errors[:name]).to include("can't be blank")
    end

    it "is invalid without a full_name" do
      repo = build(:code_repository, full_name: nil)
      expect(repo).not_to be_valid
      expect(repo.errors[:full_name]).to include("can't be blank")
    end

    it "is invalid without a slug when name is also blank" do
      repo = build(:code_repository, name: nil, slug: nil)
      expect(repo).not_to be_valid
      expect(repo.errors[:slug]).to include("can't be blank")
    end

    it "is invalid without a github_id" do
      repo = build(:code_repository, github_id: nil)
      expect(repo).not_to be_valid
      expect(repo.errors[:github_id]).to include("can't be blank")
    end

    it "requires unique slug" do
      create(:code_repository, slug: "my-repo")
      duplicate = build(:code_repository, slug: "my-repo")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:slug]).to include("has already been taken")
    end

    it "requires unique github_id" do
      create(:code_repository, github_id: 12345)
      duplicate = build(:code_repository, github_id: 12345)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:github_id]).to include("has already been taken")
    end
  end

  describe "scopes" do
    it ".visible returns only visible repos" do
      visible = create(:code_repository, visible: true)
      create(:code_repository, :hidden)

      expect(CodeRepository.visible).to eq([visible])
    end

    it ".synced returns only synced repos" do
      synced = create(:code_repository, last_synced_at: 1.hour.ago)
      create(:code_repository, :unsynced)

      expect(CodeRepository.synced).to eq([synced])
    end

    it ".ordered sorts by stargazers_count desc then name asc" do
      repo_a = create(:code_repository, name: "alpha", stargazers_count: 10)
      repo_b = create(:code_repository, name: "beta", stargazers_count: 20)
      repo_c = create(:code_repository, name: "charlie", stargazers_count: 10)

      expect(CodeRepository.ordered).to eq([repo_b, repo_a, repo_c])
    end

    it ".browsable combines visible, synced, and ordered" do
      browsable = create(:code_repository, visible: true, last_synced_at: 1.hour.ago, stargazers_count: 5)
      create(:code_repository, :hidden)
      create(:code_repository, :unsynced)

      expect(CodeRepository.browsable).to eq([browsable])
    end
  end

  describe "#bare_repo_path" do
    it "returns the expected path under storage/repos" do
      repo = build(:code_repository, slug: "my-repo")
      expect(repo.bare_repo_path.to_s).to end_with("storage/repos/my-repo.git")
    end
  end

  describe "#cloned?" do
    it "returns false when the directory does not exist" do
      repo = build(:code_repository, slug: "nonexistent-repo")
      expect(repo.cloned?).to be false
    end
  end

  describe "#to_param" do
    it "returns the slug" do
      repo = build(:code_repository, slug: "my-repo")
      expect(repo.to_param).to eq("my-repo")
    end
  end

  describe "slug generation" do
    it "auto-generates slug from name when blank" do
      repo = build(:code_repository, name: "My Cool Repo", slug: nil)
      repo.valid?
      expect(repo.slug).to eq("my-cool-repo")
    end

    it "does not overwrite an existing slug" do
      repo = build(:code_repository, name: "My Cool Repo", slug: "custom-slug")
      repo.valid?
      expect(repo.slug).to eq("custom-slug")
    end
  end
end
