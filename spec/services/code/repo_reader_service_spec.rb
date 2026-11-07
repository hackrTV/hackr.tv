require "rails_helper"

RSpec.describe Code::RepoReaderService do
  let(:repository) { build(:code_repository, slug: "test-repo", default_branch: "main") }
  let(:service) { described_class.new(repository) }
  let(:repo_path) { repository.bare_repo_path.to_s }

  def ok(output)
    [output, instance_double(Process::Status, success?: true)]
  end

  def failed
    ["", instance_double(Process::Status, success?: false)]
  end

  describe "#tree" do
    it "lists one ls-tree -l -z call as entries with type, sha and size, directories first" do
      ls_output = [
        "100644 blob aaaa1111aaaa1111aaaa1111aaaa1111aaaa1111     120\tREADME.md",
        "040000 tree bbbb2222bbbb2222bbbb2222bbbb2222bbbb2222       -\tlib",
        "040000 tree cccc3333cccc3333cccc3333cccc3333cccc3333       -\tsrc",
        "100644 blob dddd4444dddd4444dddd4444dddd4444dddd4444      12\t.gitignore",
        "160000 commit eeee5555eeee5555eeee5555eeee5555eeee5555       -\tvendor/sub"
      ].map { |line| "#{line}\0" }.join
      allow(Open3).to receive(:capture2)
        .with("git", "-C", repo_path, "ls-tree", "-l", "-z", "main")
        .and_return(ok(ls_output))

      entries = service.tree

      expect(entries.map { |e| e[:name] }).to eq(%w[lib src .gitignore README.md vendor/sub])
      expect(entries.map { |e| e[:type] }).to eq(%w[tree tree blob blob commit])
      expect(entries.find { |e| e[:name] == "lib" }).to include(sha: "bbbb2222bbbb2222bbbb2222bbbb2222bbbb2222", size: nil, path: "lib")
      expect(entries.find { |e| e[:name] == "README.md" }).to include(size: 120, path: "README.md")
      expect(Open3).to have_received(:capture2).once
    end

    it "keeps names with spaces and non-ASCII characters as git stores them" do
      allow(Open3).to receive(:capture2)
        .with("git", "-C", repo_path, "ls-tree", "-l", "-z", "main")
        .and_return(ok("100644 blob aaaa1111aaaa1111aaaa1111aaaa1111aaaa1111       9\tcafé notes.md\0"))

      expect(service.tree.first).to include(name: "café notes.md", path: "café notes.md")
    end

    it "supports subdirectory paths" do
      allow(Open3).to receive(:capture2)
        .with("git", "-C", repo_path, "ls-tree", "-l", "-z", "main:lib")
        .and_return(ok("100644 blob aaaa1111aaaa1111aaaa1111aaaa1111aaaa1111      40\tfile.rb\0"))

      entries = service.tree("lib")

      expect(entries.length).to eq(1)
      expect(entries.first).to include(path: "lib/file.rb", name: "file.rb", type: "blob", size: 40)
    end

    it "raises NotFoundError when path does not exist" do
      allow(Open3).to receive(:capture2)
        .with("git", "-C", repo_path, "ls-tree", "-l", "-z", "main:nonexistent")
        .and_return(failed)

      expect { service.tree("nonexistent") }.to raise_error(Code::RepoReaderService::NotFoundError)
    end

    it "returns empty array for empty directory" do
      allow(Open3).to receive(:capture2)
        .with("git", "-C", repo_path, "ls-tree", "-l", "-z", "main")
        .and_return(ok(""))

      expect(service.tree).to eq([])
    end
  end

  describe "#blob" do
    def stub_entry(path, type: "blob", size: 42, sha: "ffff0000ffff0000ffff0000ffff0000ffff0000")
      allow(Open3).to receive(:capture2)
        .with("git", "-C", repo_path, "ls-tree", "-l", "-z", "main", "--", path)
        .and_return(ok("100644 #{type} #{sha}    #{size}\t#{path}\0"))
    end

    def stub_content(sha, content)
      allow(Open3).to receive(:capture2)
        .with("git", "-C", repo_path, "cat-file", "blob", sha)
        .and_return(ok(content))
    end

    it "resolves the entry with ls-tree -l -z and reads the blob by sha" do
      stub_entry("app.rb", size: 42, sha: "abcd" * 10)
      stub_content("abcd" * 10, "puts 'hello'\n")

      result = service.blob("app.rb")

      expect(result).to include(path: "app.rb", name: "app.rb", content: "puts 'hello'\n", size: 42, sha: "abcd" * 10, language: "ruby")
    end

    it "raises BinaryFileError for binary extensions without touching git" do
      allow(Open3).to receive(:capture2)
      expect { service.blob("image.png") }.to raise_error(Code::RepoReaderService::BinaryFileError)
      expect(Open3).not_to have_received(:capture2)
    end

    it "raises BinaryFileError for files with null bytes" do
      stub_entry("data.txt", size: 10)
      stub_content("ffff0000ffff0000ffff0000ffff0000ffff0000", "hello\x00world")

      expect { service.blob("data.txt") }.to raise_error(Code::RepoReaderService::BinaryFileError)
    end

    it "raises FileTooLargeError for files over 1MB before reading them" do
      stub_entry("big.rb", size: 2_000_000)
      allow(Open3).to receive(:capture2).with("git", "-C", repo_path, "cat-file", "blob", anything)

      expect { service.blob("big.rb") }.to raise_error(Code::RepoReaderService::FileTooLargeError)
      expect(Open3).not_to have_received(:capture2).with("git", "-C", repo_path, "cat-file", "blob", anything)
    end

    it "raises NotFoundError when the path is missing or is a directory" do
      allow(Open3).to receive(:capture2)
        .with("git", "-C", repo_path, "ls-tree", "-l", "-z", "main", "--", "missing.rb")
        .and_return(ok(""))
      expect { service.blob("missing.rb") }.to raise_error(Code::RepoReaderService::NotFoundError)

      stub_entry("lib", type: "tree", size: "-")
      expect { service.blob("lib") }.to raise_error(Code::RepoReaderService::NotFoundError)
    end

    it "raises NotFoundError when the pathspec lists a directory's contents instead of one entry" do
      allow(Open3).to receive(:capture2)
        .with("git", "-C", repo_path, "ls-tree", "-l", "-z", "main", "--", "lib/.")
        .and_return(ok("100644 blob aaaa1111aaaa1111aaaa1111aaaa1111aaaa1111      40\tlib/a.rb\0" \
          "100644 blob bbbb2222bbbb2222bbbb2222bbbb2222bbbb2222      40\tlib/b.rb\0"))
      allow(Open3).to receive(:capture2)
        .with("git", "-C", repo_path, "ls-tree", "-l", "-z", "main", "--", ".")
        .and_return(ok("100644 blob aaaa1111aaaa1111aaaa1111aaaa1111aaaa1111      40\t.gitignore\0"))
      allow(Open3).to receive(:capture2).with("git", "-C", repo_path, "cat-file", "blob", anything)

      expect { service.blob("lib/.") }.to raise_error(Code::RepoReaderService::NotFoundError)
      expect { service.blob(".") }.to raise_error(Code::RepoReaderService::NotFoundError)
      expect(Open3).not_to have_received(:capture2).with("git", "-C", repo_path, "cat-file", "blob", anything)
    end

    it "scrubs invalid UTF-8" do
      stub_entry("latin.txt", size: 5)
      stub_content("ffff0000ffff0000ffff0000ffff0000ffff0000", "caf\xE9\n".b)

      expect(service.blob("latin.txt")[:content]).to eq("caf?\n")
    end

    it "detects language from file extension" do
      %w[app.ts style.css main.go].each { |path| stub_entry(path, size: 10) }
      stub_content("ffff0000ffff0000ffff0000ffff0000ffff0000", "content\n")

      expect(service.blob("app.ts")[:language]).to eq("typescript")
      expect(service.blob("style.css")[:language]).to eq("css")
      expect(service.blob("main.go")[:language]).to eq("go")
    end
  end
end
