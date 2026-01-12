# frozen_string_literal: true

# rbs_inline: enabled

require "fileutils"
require "open3"

class GitHubRepoClient
  class Error < StandardError; end
  class CloneError < Error; end
  class InvalidUrlError < Error; end

  DOCUMENT_EXTENSIONS = %w[.md .txt .rst].freeze
  MAX_FILE_SIZE = 50.kilobytes
  MAX_TOTAL_SIZE = 200.kilobytes

  # 프로젝트 유형별 설정 파일
  CONFIG_FILES = {
    rails: %w[config/application.rb config/routes.rb config/database.yml db/schema.rb],
    gem: [], # *.gemspec은 별도 처리
    node: %w[package.json tsconfig.json],
    python: %w[pyproject.toml setup.py setup.cfg requirements.txt],
    go: %w[go.mod],
    rust: %w[Cargo.toml],
    java_maven: %w[pom.xml],
    java_gradle: %w[build.gradle build.gradle.kts]
  }.freeze

  attr_reader :repo_url, :owner, :repo_name

  #: (repo_url: String) -> void
  def initialize(repo_url:)
    @repo_url = normalize_url(repo_url)
    parse_repo_info
  end

  # 저장소 정보를 추출하여 반환
  #: () -> Hash[Symbol, untyped]
  def fetch_repo_info
    Dir.mktmpdir("github_repo_") do |dir|
      clone_repo(dir)

      {
        url: repo_url,
        owner: owner,
        name: repo_name,
        documents: collect_root_documents(dir),
        structure: get_directory_structure(dir),
        config_files: collect_config_files(dir),
        project_type: detect_project_type(dir),
        recent_commits: get_recent_commits(dir)
      }
    end
  end

  private

  #: (String url) -> String
  def normalize_url(url)
    url = url.strip
    # .git 확장자 제거
    url = url.sub(/\.git\z/, "")
    # HTTPS URL로 정규화
    if url.match?(%r{^git@github\.com:})
      url = url.sub(%r{^git@github\.com:}, "https://github.com/")
    end
    url
  end

  #: () -> void
  def parse_repo_info
    match = repo_url.match(%r{github\.com/([^/]+)/([^/]+)})
    raise InvalidUrlError, "Invalid GitHub URL: #{repo_url}" unless match

    @owner = match[1]
    @repo_name = match[2]
  end

  #: (String dir) -> void
  def clone_repo(dir)
    # Shallow clone (depth 1) - 히스토리 없이 최신 상태만
    stdout, stderr, status = Open3.capture3(
      "git", "clone", "--depth", "1", "--single-branch", repo_url, dir,
      chdir: File.dirname(dir)
    )

    unless status.success?
      raise CloneError, "Failed to clone repository: #{stderr}"
    end
  end

  # 루트 디렉토리의 문서 파일 수집 (.md, .txt, .rst, LICENSE)
  #: (String dir) -> Array[Hash[Symbol, String]]
  def collect_root_documents(dir)
    documents = []
    total_size = 0

    Dir.children(dir).sort.each do |filename|
      filepath = File.join(dir, filename)
      next unless File.file?(filepath)
      next if filename.start_with?(".")

      # 문서 파일 확인
      ext = File.extname(filename).downcase
      is_document = DOCUMENT_EXTENSIONS.include?(ext) ||
                    filename.upcase == "LICENSE" ||
                    filename.upcase == "LICENCE"

      next unless is_document

      content = read_with_limit(filepath)
      next if content.nil?

      total_size += content.bytesize
      break if total_size > MAX_TOTAL_SIZE

      documents << { name: filename, content: content }
    end

    documents
  end

  # 디렉토리 구조를 트리 형태로 반환 (최대 2뎁스)
  #: (String dir, ?Integer depth, ?Integer max_depth) -> Array[String]
  def get_directory_structure(dir, depth = 0, max_depth = 2)
    return [] if depth > max_depth

    structure = []
    entries = Dir.children(dir).sort.reject { |e| e.start_with?(".") }

    entries.each do |entry|
      filepath = File.join(dir, entry)
      prefix = "  " * depth

      if File.directory?(filepath)
        structure << "#{prefix}#{entry}/"
        structure.concat(get_directory_structure(filepath, depth + 1, max_depth))
      else
        structure << "#{prefix}#{entry}" if depth < max_depth
      end
    end

    structure
  end

  # 프로젝트 유형 감지
  #: (String dir) -> Symbol
  def detect_project_type(dir)
    files = Dir.children(dir)

    return :rails if File.exist?(File.join(dir, "config/application.rb"))
    return :gem if files.any? { |f| f.end_with?(".gemspec") }
    return :node if files.include?("package.json")
    return :python if files.include?("pyproject.toml") || files.include?("setup.py")
    return :go if files.include?("go.mod")
    return :rust if files.include?("Cargo.toml")
    return :java_maven if files.include?("pom.xml")
    return :java_gradle if files.include?("build.gradle") || files.include?("build.gradle.kts")

    :unknown
  end

  # 프로젝트 유형에 맞는 설정 파일 수집
  #: (String dir) -> Array[Hash[Symbol, String]]
  def collect_config_files(dir)
    project_type = detect_project_type(dir)
    config_files = []

    # Gemfile은 Ruby 프로젝트 공통
    if File.exist?(File.join(dir, "Gemfile"))
      content = read_with_limit(File.join(dir, "Gemfile"))
      config_files << { name: "Gemfile", content: content } if content
    end

    # gemspec 파일 처리
    if project_type == :gem
      Dir.glob(File.join(dir, "*.gemspec")).each do |gemspec|
        content = read_with_limit(gemspec)
        config_files << { name: File.basename(gemspec), content: content } if content
      end
    end

    # 프로젝트 유형별 설정 파일
    CONFIG_FILES[project_type]&.each do |config_path|
      filepath = File.join(dir, config_path)
      next unless File.exist?(filepath)

      content = read_with_limit(filepath)
      config_files << { name: config_path, content: content } if content
    end

    config_files
  end

  # 최근 커밋 메시지 가져오기
  #: (String dir, ?Integer limit) -> Array[Hash[Symbol, String]]
  def get_recent_commits(dir, limit = 10)
    stdout, _stderr, status = Open3.capture3(
      "git", "log", "--oneline", "-n", limit.to_s, "--format=%h|%s|%an|%ad",
      "--date=short",
      chdir: dir
    )

    return [] unless status.success?

    stdout.lines.map do |line|
      parts = line.strip.split("|", 4)
      {
        hash: parts[0],
        message: parts[1],
        author: parts[2],
        date: parts[3]
      }
    end
  end

  # 파일 크기 제한을 적용하여 읽기
  #: (String filepath) -> String?
  def read_with_limit(filepath)
    return nil unless File.exist?(filepath)
    return nil if File.size(filepath) > MAX_FILE_SIZE

    File.read(filepath, encoding: "UTF-8")
  rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
    # 바이너리 파일이거나 인코딩 문제가 있으면 스킵
    nil
  end
end
