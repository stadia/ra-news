# frozen_string_literal: true

# rbs_inline: enabled

class GitHubSiteJob < ApplicationJob
  queue_as :default

  # GitHub 저장소 URL을 받아 Article을 생성
  #: (String repo_url, ?site_id: Integer?) -> void
  def perform(repo_url, site_id: nil)
    client = GitHubRepoClient.new(repo_url: repo_url)
    repo_info = client.fetch_repo_info

    # 이미 동일한 URL로 Article이 존재하는지 확인
    return if Article.exists?(origin_url: repo_info[:url])

    site = find_or_create_site(site_id)
    article = create_article_from_repo(repo_info, site)

    return unless article.persisted?

    # AI 요약 생성을 위해 ArticleJob 호출
    ArticleJob.perform_later(article.id)
  end

  private

  DEFAULT_GITHUB_SITE_NAME = "GitHub Repositories".freeze

  #: (Integer? site_id) -> Site
  def find_or_create_site(site_id)
    return Site.find(site_id) if site_id

    Site.find_or_create_by!(name: DEFAULT_GITHUB_SITE_NAME, client: :github) do |site|
      site.base_uri = "https://github.com"
    end
  end

  #: (Hash[Symbol, untyped] repo_info, Site site) -> Article
  def create_article_from_repo(repo_info, site)
    body = format_repo_body(repo_info)

    Article.create!(
      url: repo_info[:url],
      origin_url: repo_info[:url],
      title: "#{repo_info[:owner]}/#{repo_info[:name]}",
      body: body,
      host: "github.com",
      site: site,
      published_at: Time.zone.now
    )
  end

  # 저장소 정보를 Article body로 포맷팅
  #: (Hash[Symbol, untyped] repo_info) -> String
  def format_repo_body(repo_info)
    sections = []

    # 프로젝트 기본 정보
    sections << "# #{repo_info[:owner]}/#{repo_info[:name]}"
    sections << ""
    sections << "**Project Type:** #{repo_info[:project_type]}"
    sections << "**URL:** #{repo_info[:url]}"
    sections << ""

    # 문서 파일들
    if repo_info[:documents].any?
      sections << "## Documents"
      sections << ""
      repo_info[:documents].each do |doc|
        sections << "### #{doc[:name]}"
        sections << ""
        sections << doc[:content]
        sections << ""
      end
    end

    # 디렉토리 구조
    if repo_info[:structure].any?
      sections << "## Directory Structure"
      sections << ""
      sections << "```"
      sections << repo_info[:structure].join("\n")
      sections << "```"
      sections << ""
    end

    # 설정 파일들
    if repo_info[:config_files].any?
      sections << "## Configuration Files"
      sections << ""
      repo_info[:config_files].each do |config|
        sections << "### #{config[:name]}"
        sections << ""
        sections << "```"
        sections << config[:content]
        sections << "```"
        sections << ""
      end
    end

    # 최근 커밋
    if repo_info[:recent_commits].any?
      sections << "## Recent Commits"
      sections << ""
      repo_info[:recent_commits].each do |commit|
        sections << "- #{commit[:hash]} #{commit[:message]} (#{commit[:author]}, #{commit[:date]})"
      end
      sections << ""
    end

    sections.join("\n")
  end
end
