require "rails_helper"

RSpec.describe Code::RepoReaderService do
  let(:repository) { build(:code_repository, slug: "test-repo", default_branch: "main") }
  let(:service) { described_class.new(repository) }
  let(:repo_path) { repository.bare_repo_path.to_s }

  describe "#tree" do
    it "returns sorted entries with directories first" do
      ls_output = "README.md\nlib\nsrc\n.gitignore\n"
      allow(Open3).to receive(:capture2)
        .with("git", "-C", repo_path, "ls-tree", "--name-only", "main")
        .and_return([ls_output, instance_double(Process::Status, success?: true)])

      # Stub detect_entry_type calls
      allow(Open3).to receive(:capture2)
        .with("git", "-C", repo_path, "cat-file", "-t", anything)
        .and_return(["blob\n", instance_double(Process::Status, success?: true)])

      allow(Open3).to receive(:capture2)
        .with("git", "-C", repo_path, "cat-file", "-t", "main:lib")
        .and_return(["tree\n", instance_double(Process::Status, success?: true)])

      allow(Open3).to receive(:capture2)
        .with("git", "-C", repo_path, "cat-file", "-t", "main:src")
        .and_return(["tree\n", instance_double(Process::Status, success?: true)])

      entries = service.tree

      expect(entries.first(2).map { |e| e[:type] }).to eq(%w[tree tree])
      expect(entries.last(2).map { |e| e[:type] }).to eq(%w[blob blob])
    end

    it "supports subdirectory paths" do
      ls_output = "file.rb\n"
      allow(Open3).to receive(:capture2)
        .with("git", "-C", repo_path, "ls-tree", "--name-only", "main:lib")
        .and_return([ls_output, instance_double(Process::Status, success?: true)])

      allow(Open3).to receive(:capture2)
        .with("git", "-C", repo_path, "cat-file", "-t", "main:lib/file.rb")
        .and_return(["blob\n", instance_double(Process::Status, success?: true)])

      entries = service.tree("lib")

      expect(entries.length).to eq(1)
      expect(entries.first[:path]).to eq("lib/file.rb")
    end

    it "raises NotFoundError when path does not exist" do
      allow(Open3).to receive(:capture2)
        .with("git", "-C", repo_path, "ls-tree", "--name-only", "main:nonexistent")
        .and_return(["", instance_double(Process::Status, success?: false)])

      expect { service.tree("nonexistent") }.to raise_error(Code::RepoReaderService::NotFoundError)
    end

    it "returns empty array for empty directory" do
      allow(Open3).to receive(:capture2)
        .with("git", "-C", repo_path, "ls-tree", "--name-only", "main")
        .and_return(["", instance_double(Process::Status, success?: true)])

      expect(service.tree).to eq([])
    end
  end

  describe "#blob" do
    it "returns file content with metadata" do
      allow(Open3).to receive(:capture2)
        .with("git", "-C", repo_path, "cat-file", "-s", "main:app.rb")
        .and_return(["42\n", instance_double(Process::Status, success?: true)])

      allow(Open3).to receive(:capture2)
        .with("git", "-C", repo_path, "show", "main:app.rb")
        .and_return(["puts 'hello'\n", instance_double(Process::Status, success?: true)])

      result = service.blob("app.rb")

      expect(result[:path]).to eq("app.rb")
      expect(result[:name]).to eq("app.rb")
      expect(result[:content]).to eq("puts 'hello'\n")
      expect(result[:size]).to eq(42)
      expect(result[:language]).to eq("ruby")
    end

    it "raises BinaryFileError for binary extensions" do
      expect { service.blob("image.png") }.to raise_error(Code::RepoReaderService::BinaryFileError)
    end

    it "raises BinaryFileError for files with null bytes" do
      allow(Open3).to receive(:capture2)
        .with("git", "-C", repo_path, "cat-file", "-s", "main:data.txt")
        .and_return(["10\n", instance_double(Process::Status, success?: true)])

      allow(Open3).to receive(:capture2)
        .with("git", "-C", repo_path, "show", "main:data.txt")
        .and_return(["hello\x00world", instance_double(Process::Status, success?: true)])

      expect { service.blob("data.txt") }.to raise_error(Code::RepoReaderService::BinaryFileError)
    end

    it "raises FileTooLargeError for files over 1MB" do
      allow(Open3).to receive(:capture2)
        .with("git", "-C", repo_path, "cat-file", "-s", "main:big.rb")
        .and_return(["2000000\n", instance_double(Process::Status, success?: true)])

      expect { service.blob("big.rb") }.to raise_error(Code::RepoReaderService::FileTooLargeError)
    end

    it "raises NotFoundError when file does not exist" do
      allow(Open3).to receive(:capture2)
        .with("git", "-C", repo_path, "cat-file", "-s", "main:missing.rb")
        .and_return(["", instance_double(Process::Status, success?: false)])

      expect { service.blob("missing.rb") }.to raise_error(Code::RepoReaderService::NotFoundError)
    end

    it "detects language from file extension" do
      allow(Open3).to receive(:capture2)
        .with("git", "-C", repo_path, "cat-file", "-s", anything)
        .and_return(["10\n", instance_double(Process::Status, success?: true)])

      allow(Open3).to receive(:capture2)
        .with("git", "-C", repo_path, "show", anything)
        .and_return(["content\n", instance_double(Process::Status, success?: true)])

      expect(service.blob("app.ts")[:language]).to eq("typescript")
      expect(service.blob("style.css")[:language]).to eq("css")
      expect(service.blob("main.go")[:language]).to eq("go")
    end
  end
end
