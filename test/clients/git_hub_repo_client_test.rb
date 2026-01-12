# frozen_string_literal: true

require "test_helper"

class GitHubRepoClientTest < ActiveSupport::TestCase
  # ========== Initialization Tests ==========

  test "HTTPS URL로 초기화해야 한다" do
    client = GitHubRepoClient.new(repo_url: "https://github.com/rails/rails")

    assert_equal "https://github.com/rails/rails", client.repo_url
    assert_equal "rails", client.owner
    assert_equal "rails", client.repo_name
  end

  test ".git 확장자가 있는 URL을 정규화해야 한다" do
    client = GitHubRepoClient.new(repo_url: "https://github.com/rails/rails.git")

    assert_equal "https://github.com/rails/rails", client.repo_url
    assert_equal "rails", client.owner
    assert_equal "rails", client.repo_name
  end

  test "SSH URL을 HTTPS로 변환해야 한다" do
    client = GitHubRepoClient.new(repo_url: "git@github.com:rails/rails.git")

    assert_equal "https://github.com/rails/rails", client.repo_url
    assert_equal "rails", client.owner
    assert_equal "rails", client.repo_name
  end

  test "URL 앞뒤 공백을 제거해야 한다" do
    client = GitHubRepoClient.new(repo_url: "  https://github.com/rails/rails  ")

    assert_equal "https://github.com/rails/rails", client.repo_url
  end

  test "유효하지 않은 GitHub URL에 대해 오류를 발생시켜야 한다" do
    assert_raises(GitHubRepoClient::InvalidUrlError) do
      GitHubRepoClient.new(repo_url: "https://gitlab.com/rails/rails")
    end
  end

  test "owner/repo가 없는 URL에 대해 오류를 발생시켜야 한다" do
    assert_raises(GitHubRepoClient::InvalidUrlError) do
      GitHubRepoClient.new(repo_url: "https://github.com/")
    end
  end

  # ========== URL Parsing Tests ==========

  test "다양한 GitHub URL 형식을 처리해야 한다" do
    urls = [
      "https://github.com/owner/repo",
      "https://github.com/owner/repo.git",
      "http://github.com/owner/repo",
      "git@github.com:owner/repo.git",
      "git@github.com:owner/repo"
    ]

    urls.each do |url|
      client = GitHubRepoClient.new(repo_url: url)
      assert_equal "owner", client.owner, "Failed for URL: #{url}"
      assert_equal "repo", client.repo_name, "Failed for URL: #{url}"
    end
  end

  # ========== Constants Tests ==========

  test "적절한 파일 크기 제한을 설정해야 한다" do
    assert_equal 50.kilobytes, GitHubRepoClient::MAX_FILE_SIZE
    assert_equal 200.kilobytes, GitHubRepoClient::MAX_TOTAL_SIZE
  end

  test "문서 확장자를 정의해야 한다" do
    expected_extensions = %w[.md .txt .rst]
    assert_equal expected_extensions, GitHubRepoClient::DOCUMENT_EXTENSIONS
  end

  test "프로젝트 유형별 설정 파일을 정의해야 한다" do
    assert_includes GitHubRepoClient::CONFIG_FILES.keys, :rails
    assert_includes GitHubRepoClient::CONFIG_FILES.keys, :gem
    assert_includes GitHubRepoClient::CONFIG_FILES.keys, :node
    assert_includes GitHubRepoClient::CONFIG_FILES.keys, :python
    assert_includes GitHubRepoClient::CONFIG_FILES.keys, :go
    assert_includes GitHubRepoClient::CONFIG_FILES.keys, :rust
  end

  # ========== Project Type Detection Tests ==========

  test "Rails 프로젝트를 감지해야 한다" do
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "config"))
      File.write(File.join(dir, "config/application.rb"), "")

      client = GitHubRepoClient.new(repo_url: "https://github.com/test/test")
      project_type = client.send(:detect_project_type, dir)

      assert_equal :rails, project_type
    end
  end

  test "Ruby Gem 프로젝트를 감지해야 한다" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "my_gem.gemspec"), "")

      client = GitHubRepoClient.new(repo_url: "https://github.com/test/test")
      project_type = client.send(:detect_project_type, dir)

      assert_equal :gem, project_type
    end
  end

  test "Node.js 프로젝트를 감지해야 한다" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "package.json"), "{}")

      client = GitHubRepoClient.new(repo_url: "https://github.com/test/test")
      project_type = client.send(:detect_project_type, dir)

      assert_equal :node, project_type
    end
  end

  test "Python 프로젝트를 감지해야 한다" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "pyproject.toml"), "")

      client = GitHubRepoClient.new(repo_url: "https://github.com/test/test")
      project_type = client.send(:detect_project_type, dir)

      assert_equal :python, project_type
    end
  end

  test "Go 프로젝트를 감지해야 한다" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "go.mod"), "")

      client = GitHubRepoClient.new(repo_url: "https://github.com/test/test")
      project_type = client.send(:detect_project_type, dir)

      assert_equal :go, project_type
    end
  end

  test "Rust 프로젝트를 감지해야 한다" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "Cargo.toml"), "")

      client = GitHubRepoClient.new(repo_url: "https://github.com/test/test")
      project_type = client.send(:detect_project_type, dir)

      assert_equal :rust, project_type
    end
  end

  test "알 수 없는 프로젝트 유형은 :unknown을 반환해야 한다" do
    Dir.mktmpdir do |dir|
      client = GitHubRepoClient.new(repo_url: "https://github.com/test/test")
      project_type = client.send(:detect_project_type, dir)

      assert_equal :unknown, project_type
    end
  end

  # ========== Document Collection Tests ==========

  test "루트의 문서 파일을 수집해야 한다" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "README.md"), "# Test Project")
      File.write(File.join(dir, "CHANGELOG.md"), "## v1.0.0")
      File.write(File.join(dir, "LICENSE"), "MIT License")
      File.write(File.join(dir, "notes.txt"), "Some notes")

      client = GitHubRepoClient.new(repo_url: "https://github.com/test/test")
      documents = client.send(:collect_root_documents, dir)

      names = documents.map { |d| d[:name] }
      assert_includes names, "README.md"
      assert_includes names, "CHANGELOG.md"
      assert_includes names, "LICENSE"
      assert_includes names, "notes.txt"
    end
  end

  test "숨김 파일은 제외해야 한다" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, ".hidden.md"), "Hidden")
      File.write(File.join(dir, "README.md"), "Visible")

      client = GitHubRepoClient.new(repo_url: "https://github.com/test/test")
      documents = client.send(:collect_root_documents, dir)

      names = documents.map { |d| d[:name] }
      assert_not_includes names, ".hidden.md"
      assert_includes names, "README.md"
    end
  end

  test "파일 크기 제한을 적용해야 한다" do
    Dir.mktmpdir do |dir|
      # 크기 제한보다 큰 파일 생성
      large_content = "x" * (GitHubRepoClient::MAX_FILE_SIZE + 1)
      File.write(File.join(dir, "large.md"), large_content)
      File.write(File.join(dir, "small.md"), "Small content")

      client = GitHubRepoClient.new(repo_url: "https://github.com/test/test")
      documents = client.send(:collect_root_documents, dir)

      names = documents.map { |d| d[:name] }
      assert_not_includes names, "large.md"
      assert_includes names, "small.md"
    end
  end

  # ========== Directory Structure Tests ==========

  test "디렉토리 구조를 반환해야 한다" do
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "src"))
      FileUtils.mkdir_p(File.join(dir, "test"))
      File.write(File.join(dir, "README.md"), "")
      File.write(File.join(dir, "src/main.rb"), "")

      client = GitHubRepoClient.new(repo_url: "https://github.com/test/test")
      structure = client.send(:get_directory_structure, dir)

      assert_includes structure, "README.md"
      assert_includes structure, "src/"
      assert_includes structure, "test/"
    end
  end

  test "숨김 디렉토리는 구조에서 제외해야 한다" do
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, ".git"))
      FileUtils.mkdir_p(File.join(dir, "src"))

      client = GitHubRepoClient.new(repo_url: "https://github.com/test/test")
      structure = client.send(:get_directory_structure, dir)

      assert_not structure.any? { |s| s.include?(".git") }
      assert_includes structure, "src/"
    end
  end

  # ========== Config Files Collection Tests ==========

  test "프로젝트 유형에 맞는 설정 파일을 수집해야 한다" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "package.json"), '{"name": "test"}')
      File.write(File.join(dir, "tsconfig.json"), '{}')

      client = GitHubRepoClient.new(repo_url: "https://github.com/test/test")
      config_files = client.send(:collect_config_files, dir)

      names = config_files.map { |c| c[:name] }
      assert_includes names, "package.json"
      assert_includes names, "tsconfig.json"
    end
  end

  test "Gemfile을 Ruby 프로젝트에서 수집해야 한다" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "Gemfile"), 'source "https://rubygems.org"')

      client = GitHubRepoClient.new(repo_url: "https://github.com/test/test")
      config_files = client.send(:collect_config_files, dir)

      names = config_files.map { |c| c[:name] }
      assert_includes names, "Gemfile"
    end
  end

  # ========== Error Handling Tests ==========

  test "클론 실패 시 CloneError를 발생시켜야 한다" do
    client = GitHubRepoClient.new(repo_url: "https://github.com/nonexistent/nonexistent-repo-12345")

    assert_raises(GitHubRepoClient::CloneError) do
      client.fetch_repo_info
    end
  end
end
