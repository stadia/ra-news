# frozen_string_literal: true

require "test_helper"

class GitHubSiteJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @github_site = sites(:github_repos)
    @repo_url = "https://github.com/rails/rails"
    @mock_repo_info = {
      url: @repo_url,
      owner: "rails",
      name: "rails",
      documents: [
        { name: "README.md", content: "# Rails\n\nRuby on Rails framework" }
      ],
      structure: [ "README.md", "Gemfile", "lib/", "test/" ],
      config_files: [
        { name: "Gemfile", content: 'source "https://rubygems.org"' }
      ],
      project_type: :rails,
      recent_commits: [
        { hash: "abc1234", message: "Fix bug", author: "DHH", date: "2024-01-01" }
      ]
    }
  end

  # ========== Job Execution Tests ==========

  test "저장소 정보로 Article을 생성해야 한다" do
    mock_client = Minitest::Mock.new
    mock_client.expect :fetch_repo_info, @mock_repo_info

    GitHubRepoClient.stub :new, mock_client do
      assert_difference "Article.count", 1 do
        perform_enqueued_jobs do
          ArticleJob.stub :perform_later, true do
            GitHubSiteJob.perform_now(@repo_url, site_id: @github_site.id)
          end
        end
      end
    end

    article = Article.last
    assert_equal @repo_url, article.origin_url
    assert_equal "rails/rails", article.title
    assert_equal "github.com", article.host
    assert_equal @github_site, article.site

    mock_client.verify
  end

  test "이미 존재하는 URL에 대해 중복 Article을 생성하지 않아야 한다" do
    # 먼저 Article 생성
    Article.create!(
      url: @repo_url,
      origin_url: @repo_url,
      title: "Existing Article",
      site: @github_site
    )

    mock_client = Minitest::Mock.new
    mock_client.expect :fetch_repo_info, @mock_repo_info

    GitHubRepoClient.stub :new, mock_client do
      assert_no_difference "Article.count" do
        GitHubSiteJob.perform_now(@repo_url, site_id: @github_site.id)
      end
    end

    mock_client.verify
  end

  test "Site와 연결하여 Article을 생성할 수 있어야 한다" do
    site = Site.create!(name: "Custom GitHub Repos", client: :github, base_uri: @repo_url)

    mock_client = Minitest::Mock.new
    mock_client.expect :fetch_repo_info, @mock_repo_info

    GitHubRepoClient.stub :new, mock_client do
      ArticleJob.stub :perform_later, true do
        GitHubSiteJob.perform_now(@repo_url, site_id: site.id)
      end
    end

    article = Article.last
    assert_equal site, article.site

    mock_client.verify
  end

  test "Article 생성 후 ArticleJob을 호출해야 한다" do
    mock_client = Minitest::Mock.new
    mock_client.expect :fetch_repo_info, @mock_repo_info

    article_job_called = false

    GitHubRepoClient.stub :new, mock_client do
      ArticleJob.stub :perform_later, ->(id) { article_job_called = true } do
        GitHubSiteJob.perform_now(@repo_url, site_id: @github_site.id)
      end
    end

    assert article_job_called, "ArticleJob should be called after creating article"
    mock_client.verify
  end

  # ========== Body Formatting Tests ==========

  test "body에 프로젝트 정보를 포함해야 한다" do
    mock_client = Minitest::Mock.new
    mock_client.expect :fetch_repo_info, @mock_repo_info

    GitHubRepoClient.stub :new, mock_client do
      ArticleJob.stub :perform_later, true do
        GitHubSiteJob.perform_now(@repo_url, site_id: @github_site.id)
      end
    end

    article = Article.last
    body = article.body

    assert_includes body, "rails/rails"
    assert_includes body, "Project Type:** rails"
    assert_includes body, "README.md"
    assert_includes body, "Directory Structure"
    assert_includes body, "Recent Commits"

    mock_client.verify
  end

  test "문서 내용을 body에 포함해야 한다" do
    mock_client = Minitest::Mock.new
    mock_client.expect :fetch_repo_info, @mock_repo_info

    GitHubRepoClient.stub :new, mock_client do
      ArticleJob.stub :perform_later, true do
        GitHubSiteJob.perform_now(@repo_url, site_id: @github_site.id)
      end
    end

    article = Article.last
    assert_includes article.body, "Ruby on Rails framework"

    mock_client.verify
  end

  test "설정 파일 내용을 body에 포함해야 한다" do
    mock_client = Minitest::Mock.new
    mock_client.expect :fetch_repo_info, @mock_repo_info

    GitHubRepoClient.stub :new, mock_client do
      ArticleJob.stub :perform_later, true do
        GitHubSiteJob.perform_now(@repo_url, site_id: @github_site.id)
      end
    end

    article = Article.last
    assert_includes article.body, "Configuration Files"
    assert_includes article.body, "Gemfile"

    mock_client.verify
  end

  # ========== Error Handling Tests ==========

  test "GitHubRepoClient 오류를 정상적으로 처리해야 한다" do
    GitHubRepoClient.stub :new, ->(_) { raise GitHubRepoClient::CloneError, "Clone failed" } do
      assert_raises(GitHubRepoClient::CloneError) do
        GitHubSiteJob.perform_now(@repo_url, site_id: @github_site.id)
      end
    end
  end

  test "잘못된 URL에 대해 오류를 발생시켜야 한다" do
    GitHubRepoClient.stub :new, ->(_) { raise GitHubRepoClient::InvalidUrlError, "Invalid URL" } do
      assert_raises(GitHubRepoClient::InvalidUrlError) do
        GitHubSiteJob.perform_now("https://invalid-url.com", site_id: @github_site.id)
      end
    end
  end

  # ========== Queue Configuration Tests ==========

  test "default 큐에서 실행되어야 한다" do
    assert_equal "default", GitHubSiteJob.new.queue_name
  end
end
