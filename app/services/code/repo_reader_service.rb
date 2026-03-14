require "open3"

module Code
  class RepoReaderService
    class NotFoundError < StandardError; end
    class BinaryFileError < StandardError; end
    class FileTooLargeError < StandardError; end

    BINARY_EXTENSIONS = %w[
      .png .jpg .jpeg .gif .bmp .ico .svg .webp
      .mp3 .mp4 .wav .ogg .flac .aac .webm
      .zip .tar .gz .bz2 .7z .rar .xz
      .pdf .doc .docx .xls .xlsx .ppt .pptx
      .exe .dll .so .dylib .o .a
      .woff .woff2 .ttf .eot .otf
      .pyc .class .jar
      .db .sqlite .sqlite3
      .bin .dat .DS_Store
    ].freeze

    MAX_FILE_SIZE = 1_048_576 # 1MB

    def initialize(repository)
      @repository = repository
      @repo_path = repository.bare_repo_path.to_s
      @branch = repository.default_branch || "main"
    end

    def tree(path = "")
      ref = path.present? ? "#{@branch}:#{path}" : @branch
      output, status = Open3.capture2("git", "-C", @repo_path, "ls-tree", "--name-only", ref)

      raise NotFoundError, "Path not found: #{path}" unless status.success?

      entries = output.strip.split("\n").filter_map do |name|
        next if name.empty?
        entry_path = path.present? ? "#{path}/#{name}" : name
        type = detect_entry_type(entry_path)
        {name: name, path: entry_path, type: type}
      end

      # Sort: directories first, then alphabetical
      entries.sort_by { |e| [(e[:type] == "tree") ? 0 : 1, e[:name].downcase] }
    end

    def blob(path)
      ext = File.extname(path).downcase
      raise BinaryFileError, "Binary file type: #{ext}" if BINARY_EXTENSIONS.include?(ext)

      # Check file size
      size_output, size_status = Open3.capture2(
        "git", "-C", @repo_path, "cat-file", "-s", "#{@branch}:#{path}"
      )
      raise NotFoundError, "File not found: #{path}" unless size_status.success?

      size = size_output.strip.to_i
      raise FileTooLargeError, "File too large: #{size} bytes (max #{MAX_FILE_SIZE})" if size > MAX_FILE_SIZE

      output, status = Open3.capture2("git", "-C", @repo_path, "show", "#{@branch}:#{path}")
      raise NotFoundError, "File not found: #{path}" unless status.success?

      # Force UTF-8 encoding
      content = output.force_encoding("UTF-8")
      content = content.encode("UTF-8", invalid: :replace, undef: :replace, replace: "?") unless content.valid_encoding?

      # Detect binary via null bytes
      raise BinaryFileError, "Binary file detected" if content.include?("\x00")

      {
        path: path,
        name: File.basename(path),
        content: content,
        size: size,
        language: detect_language(path)
      }
    end

    private

    def detect_entry_type(path)
      _output, status = Open3.capture2(
        "git", "-C", @repo_path, "cat-file", "-t", "#{@branch}:#{path}"
      )
      return "tree" unless status.success?

      type_output, = Open3.capture2(
        "git", "-C", @repo_path, "cat-file", "-t", "#{@branch}:#{path}"
      )
      (type_output.strip == "tree") ? "tree" : "blob"
    end

    def detect_language(path)
      ext = File.extname(path).downcase
      LANGUAGE_MAP[ext] || ext.delete(".")
    end

    LANGUAGE_MAP = {
      ".rb" => "ruby",
      ".js" => "javascript",
      ".ts" => "typescript",
      ".tsx" => "typescript",
      ".jsx" => "javascript",
      ".py" => "python",
      ".go" => "go",
      ".rs" => "rust",
      ".sh" => "bash",
      ".bash" => "bash",
      ".zsh" => "bash",
      ".yml" => "yaml",
      ".yaml" => "yaml",
      ".json" => "json",
      ".md" => "markdown",
      ".html" => "html",
      ".erb" => "erb",
      ".css" => "css",
      ".scss" => "scss",
      ".sql" => "sql",
      ".xml" => "xml",
      ".toml" => "toml",
      ".rake" => "ruby",
      ".gemspec" => "ruby",
      ".lock" => "plaintext",
      ".txt" => "plaintext",
      ".cfg" => "ini",
      ".ini" => "ini",
      ".conf" => "nginx",
      ".dockerfile" => "dockerfile",
      ".c" => "c",
      ".h" => "c",
      ".cpp" => "cpp",
      ".hpp" => "cpp",
      ".java" => "java",
      ".lua" => "lua",
      ".r" => "r",
      ".swift" => "swift",
      ".kt" => "kotlin",
      ".ex" => "elixir",
      ".exs" => "elixir",
      ".erl" => "erlang",
      ".hs" => "haskell",
      ".pl" => "perl",
      ".php" => "php"
    }.freeze
  end
end
