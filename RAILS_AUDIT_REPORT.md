# Rails 코드 감사 보고서

**프로젝트**: Ruby-News
**감사 날짜**: 2026-01-22
**감사 기준**: thoughtbot Ruby Science & Testing Rails
**Rails 버전**: 8.x
**Ruby 버전**: 4.0
**테스트 프레임워크**: Minitest

---

## 📊 요약 (Executive Summary)

전체적으로 프로젝트는 **양호한 상태**이며, 최신 Rails 8 패턴과 모범 사례를 따르고 있습니다. 특히 다음 영역에서 강점을 보입니다:

✅ **강점**:
- RBS inline 타입 어노테이션 적극 활용
- Dry::Operation을 통한 Railway-Oriented Programming 패턴
- 서비스 계층의 적절한 추상화 (SocialMediaService 상속 구조)
- 포괄적인 모델 테스트 커버리지 (Article 모델: 600+ 라인)
- Soft delete (Discard gem) 일관적 적용

⚠️ **개선 영역**:
- **테스트 커버리지 부족** (Job 테스트 0%, 컨트롤러 테스트 0%, 클라이언트 테스트 0%)
- **Fat Model** (Article 모델 295줄 - Large Class 냄새)
- **콜백 복잡도** (Article 모델 - 비즈니스 로직이 콜백에 포함)
- **Service Object 네이밍** (일부 *Service 네이밍이 PORO 패턴 미준수)

---

## 📋 카테고리별 분석

### 1️⃣ Testing (테스트 품질 및 커버리지)

#### ❌ **Critical Issues**

**CRIT-TEST-01: Job 테스트 완전 누락**
- **위치**: `app/jobs/` (9개 파일)
- **문제**: 모든 Job 클래스에 테스트가 없음
  ```
  ❌ test/jobs/article_job_test.rb
  ❌ test/jobs/social_post_job_test.rb
  ❌ test/jobs/social_delete_job_test.rb
  ❌ test/jobs/rss_site_job_test.rb
  ❌ test/jobs/rss_site_page_job_test.rb
  ❌ test/jobs/youtube_site_job_test.rb
  ❌ test/jobs/gmail_article_job_test.rb
  ❌ test/jobs/article_batch_job_test.rb
  ❌ test/jobs/hacker_news_site_job_test.rb
  ```
- **영향**: 백그라운드 작업 실패 시 프로덕션 장애로 직결
- **권장사항**:
  ```ruby
  # test/jobs/article_job_test.rb
  class ArticleJobTest < ActiveJob::TestCase
    test "kept article에 대해 LLM 서비스 호출" do
      article = articles(:ruby_article)

      ArticleLlmService.expects(:call).with(article)

      perform_enqueued_jobs do
        ArticleJob.perform_later(article.id)
      end
    end

    test "discarded article은 처리 스킵" do
      article = articles(:deleted_article)

      ArticleLlmService.expects(:call).never

      ArticleJob.perform_now(article.id)
    end
  end
  ```

**CRIT-TEST-02: 컨트롤러 테스트 완전 누락**
- **위치**: `app/controllers/` (16개 컨트롤러)
- **문제**: Request spec/Controller spec 없음
- **영향**: 인증, 인가, 요청 처리 로직 미검증
- **권장사항**: 최소한 주요 컨트롤러에 대해 테스트 추가
  ```ruby
  # test/controllers/articles_controller_test.rb
  class ArticlesControllerTest < ActionDispatch::IntegrationTest
    test "인증 없이 index 접근 가능" do
      get articles_url
      assert_response :success
    end

    test "새 article 생성 시 ArticleJob 예약" do
      assert_enqueued_with(job: ArticleJob) do
        post articles_url, params: { article: { url: "https://example.com/new" } }
      end
    end

    test "중복 URL 제출 시 기존 article로 리다이렉트" do
      existing = articles(:ruby_article)
      post articles_url, params: { article: { url: existing.url } }

      assert_redirected_to article_path(existing)
    end
  end
  ```

**CRIT-TEST-03: 클라이언트 테스트 완전 누락**
- **위치**: `app/clients/` (8개 파일)
- **문제**: 외부 API 연동 클라이언트 테스트 없음
- **영향**: API 변경 시 런타임 에러 발생 위험
- **권장사항**: WebMock/VCR을 사용한 API 테스트
  ```ruby
  # test/clients/twitter_client_test.rb
  class TwitterClientTest < ActiveSupport::TestCase
    test "트윗 게시 성공" do
      stub_request(:post, "https://api.twitter.com/2/tweets")
        .to_return(status: 201, body: { data: { id: "12345" } }.to_json)

      client = TwitterClient.new
      response = client.post("Test tweet")

      assert_equal 201, response.status
      assert_equal "12345", response.body["data"]["id"]
    end
  end
  ```

#### ⚠️ **High Severity Issues**

**HIGH-TEST-01: 서비스 계층 테스트 불완전**
- **위치**: `test/services/`
- **문제**: 서비스는 있지만 엣지 케이스 테스트 부족
- **예시**: `ContentService`에서 리다이렉트 재귀 제한 (count > 3) 테스트 누락
- **권장사항**:
  ```ruby
  # test/services/content_service_test.rb에 추가
  test "리다이렉트 무한 루프 방지 (4회 제한)" do
    article = articles(:redirect_article)

    # 4번 리다이렉트 후 중단되는지 확인
    stub_request(:get, article.url)
      .to_return(status: 301, headers: { location: "https://redirect.com" })
      .times(4)

    result = ContentService.new.call(article)
    # 리다이렉트 제한으로 인해 마지막 응답이 반환되어야 함
  end
  ```

#### ✅ **Positive Findings**

**GOOD-TEST-01: Article 모델 테스트 품질 우수**
- **위치**: `test/models/article_test.rb` (637줄)
- **강점**:
  - Four Phase Test 패턴 준수
  - 엣지 케이스 철저히 테스트 (Bug fix #1, #2 주석)
  - 한국어 처리 테스트 포함
  - Performance test 포함 (`assert_queries`)
  - 타임존 처리 검증
- **모범 사례 예시**:
  ```ruby
  test "update_slug는 경로가 없는 URL을 안전하게 처리해야 한다 (Bug fix #2)" do
    article = Article.new(url: "https://example.com")

    assert_nothing_raised do
      result = article.update_slug
      assert result
    end

    article.reload
    assert_not_nil article.slug
  end
  ```

---

### 2️⃣ Security (보안)

#### ⚠️ **Medium Severity Issues**

**MED-SEC-01: Mass Assignment 취약점 가능성**
- **위치**: `app/controllers/comments_controller.rb:52`
- **문제**: `params.expect(comment: [ :body ])` 사용 - Rails 8 패턴이지만 검증 필요
- **현황**: ✅ 현재는 안전 (`:body`만 허용)
- **권장사항**: 향후 필드 추가 시 주의 (예: `parent_id` 추가 시 Nested Set 무결성 검증 필요)

**MED-SEC-02: 외부 URL 페칭 SSRF 위험**
- **위치**: `app/models/article.rb:240` (`fetch_url_content`)
- **문제**: 사용자 제공 URL을 직접 페칭
- **현황**: `should_ignore_url?`로 일부 완화
- **권장사항**: Private IP 범위 차단 추가
  ```ruby
  # app/models/article.rb
  def fetch_url_content
    uri = URI.parse(url)
    raise ArgumentError if uri.host =~ /^(127\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.)/

    Faraday.get(url)
  rescue Faraday::Error, ArgumentError => e
    logger.error "Error fetching URL #{url}: #{e.message}"
    nil
  end
  ```

#### ✅ **Positive Findings**

**GOOD-SEC-01: 커스텀 인증 시스템 적절**
- **위치**: `app/controllers/concerns/authentication.rb`, `app/models/user.rb`
- **강점**:
  - `has_secure_password` 사용 (bcrypt)
  - Email validation 및 정규화
  - Session 기반 인증
  - Role-based access control (`:admin` 등)

**GOOD-SEC-02: SQL Injection 방지 적절**
- **모든 쿼리**에서 파라미터화된 쿼리 사용
- 예: `Article.where("slug IS NOT NULL AND title_ko IS NOT NULL")`

---

### 3️⃣ Models (모델 설계)

#### 🔴 **Critical Issues**

**CRIT-MOD-01: Article 모델 - God Class / Large Class**
- **위치**: `app/models/article.rb` (295줄)
- **문제**:
  - 여러 책임 혼재 (메타데이터 추출, URL 파싱, YouTube 처리, 검색, 캐시 관리)
  - 15+ public 메서드
  - private 메서드 복잡도 높음
- **Code Smell**: Large Class, Divergent Change
- **Severity**: Critical
- **리팩토링 권장사항**:

  **Step 1: URL Processing 추출**
  ```ruby
  # app/models/articles/url_processor.rb
  module Articles
    class UrlProcessor
      include ActiveModel::Model

      attr_accessor :url, :origin_url

      def normalize
        parsed_url = URI.parse(url)
        remove_tracking_params(parsed_url)
        parsed_url.to_s
      end

      def extract_published_at
        # URL 패턴에서 날짜 추출 로직
      end

      private

      def remove_tracking_params(uri)
        query_params = URI.decode_www_form(uri.query || "").to_h
        query_params.except!("utm_source", "utm_medium", ...)
        uri.query = build_query(query_params)
      end
    end
  end

  # app/models/article.rb에서 사용
  def generate_metadata
    processor = Articles::UrlProcessor.new(url: url)
    self.url = processor.normalize
    self.published_at = processor.extract_published_at || Time.zone.now
    # ...
  end
  ```

  **Step 2: YouTube 처리 추출**
  ```ruby
  # app/models/articles/youtube_handler.rb
  module Articles
    class YoutubeHandler
      def initialize(url)
        @url = url
        @video_id = extract_video_id(url)
      end

      def video_id
        @video_id
      end

      def fetch_metadata
        return {} unless @video_id

        video = Yt::Video.new(id: @video_id)
        {
          slug: @video_id,
          published_at: video.published_at,
          title: video.title
        }
      rescue Yt::Error => e
        Rails.logger.error "YouTube API error: #{e.message}"
        {}
      end

      private

      def extract_video_id(url)
        uri = URI.parse(url)
        if uri.query.present?
          URI.decode_www_form(uri.query).to_h["v"]
        elsif uri.path.start_with?("/live")
          uri.path.split("/").last
        end
      rescue URI::InvalidURIError
        nil
      end
    end
  end

  # app/models/article.rb
  def youtube_id
    return @youtube_id if defined?(@youtube_id)
    @youtube_id = Articles::YoutubeHandler.new(url).video_id if is_youtube?
  end

  def set_youtube_metadata
    handler = Articles::YoutubeHandler.new(url)
    metadata = handler.fetch_metadata
    self.slug = metadata[:slug]
    self.published_at = metadata[:published_at]
    self.title = metadata[:title]
  end
  ```

  **Step 3: Metadata Extractor 추출**
  ```ruby
  # app/models/articles/metadata_extractor.rb
  module Articles
    class MetadataExtractor
      def initialize(html_body)
        @doc = Nokogiri::HTML5(html_body)
      end

      def title
        temp_title = @doc.at("title")&.text
        temp_title&.strip&.gsub(/\s+/, " ")
      end

      def published_at
        extract_from_time_element ||
          extract_from_date_class ||
          extract_from_text_patterns
      end

      private

      def extract_from_time_element
        time_element = @doc.at("time")
        return unless time_element

        datetime = time_element["datetime"]
        datetime ? Time.zone.parse(datetime) : parse_text(time_element.text)
      end

      def extract_from_date_class
        date_element = @doc.css(".date").first
        parse_text(date_element&.text)
      end

      def extract_from_text_patterns
        # 날짜 패턴 매칭 로직
      end
    end
  end
  ```

  **Step 4: Article 모델 간소화**
  ```ruby
  # app/models/article.rb (리팩토링 후 예상 크기: 150줄 이하)
  class Article < ApplicationRecord
    # Concerns
    include PgSearch::Model
    include Discard::Model

    # Associations, validations, scopes (변경 없음)

    # 콜백을 최소화하고 명시적 메서드 호출로 변경 검토
    before_create :generate_metadata

    def generate_metadata
      return unless url.is_a?(String)

      response = fetch_url_content
      return unless response

      handle_redirection(response)

      # Delegators로 추출
      metadata = if is_youtube?
        Articles::YoutubeHandler.new(url).fetch_metadata
      else
        extractor = Articles::MetadataExtractor.new(response.body)
        {
          slug: Articles::UrlProcessor.new(url: url).slug,
          published_at: extractor.published_at,
          title: extractor.title
        }
      end

      assign_attributes(metadata)
      self.slug ||= random_slug
      handle_slug_collision
    end

    # 간단한 위임 메서드만 남김
    def youtube_id
      Articles::YoutubeHandler.new(url).video_id if is_youtube?
    end

    # ...
  end
  ```

#### ⚠️ **High Severity Issues**

**HIGH-MOD-01: Callback 복잡도**
- **위치**: `app/models/article.rb:46-62`
- **문제**:
  ```ruby
  before_create :generate_metadata  # 외부 API 호출 포함
  after_discard { SocialDeleteJob.perform_later(id) }  # 비즈니스 로직
  after_commit :clear_rss_cache  # 캐시 관리
  before_save { self.published_at ||= Time.zone.now }
  ```
- **Code Smell**: Callback Complexity
- **영향**:
  - 테스트 어려움 (콜백 스킵 불가)
  - 예측 불가능한 부작용
  - 트랜잭션 내 외부 API 호출
- **권장사항**: **Replace Callback with Method**
  ```ruby
  # 리팩토링 전
  class Article < ApplicationRecord
    before_create :generate_metadata
  end

  # 리팩토링 후
  class Article < ApplicationRecord
    # 콜백 제거, 명시적 호출로 변경
  end

  # app/controllers/articles_controller.rb
  def create
    @article = Article.new(url: url, origin_url: url)
    @article.generate_metadata  # 명시적 호출

    if @article.save
      ArticleJob.perform_later(@article.id)
      redirect_to article_path(@article)
    else
      render :new
    end
  end

  # app/jobs/article_job.rb
  def perform(id)
    article = Article.find(id)
    ArticleLlmService.call(article)
    # LLM 처리 완료 후에만 소셜 미디어 게시
  end

  # 장점:
  # 1. 테스트 가능 (콜백 없이 Article 생성 가능)
  # 2. 명시적 제어 흐름
  # 3. 외부 API 호출이 트랜잭션 외부에서 실행
  ```

**HIGH-MOD-02: Site#init_client - Case Statement Smell**
- **위치**: `app/models/site.rb:20-34`
- **문제**:
  ```ruby
  def init_client
    case client
    when "rss", "rss_page"
      RssClient.new(base_uri: base_uri)
    when "gmail"
      Gmail.new
    when "youtube"
      return nil if channel.blank?
      Youtube::Channel.new(id: channel)
    when "hacker_news"
      HackerNews.new
    else
      raise ArgumentError
    end
  end
  ```
- **Code Smell**: Case Statement, Type Code
- **영향**: 새 클라이언트 추가 시 Shotgun Surgery
- **권장사항**: **Replace Conditional with Polymorphism**
  ```ruby
  # 옵션 1: Convention over Configuration
  # app/models/site.rb
  def init_client
    client_class = "#{client.camelize}Client".constantize
    client_class.new(site: self)
  rescue NameError
    raise ArgumentError, "Unknown client type: #{client}"
  end

  # app/clients/rss_client.rb
  class RssClient < ApplicationClient
    def initialize(site:)
      super(base_uri: site.base_uri)
    end
  end

  # app/clients/youtube_client.rb
  class YoutubeClient < ApplicationClient
    def initialize(site:)
      return nil if site.channel.blank?
      @channel = Youtube::Channel.new(id: site.channel)
    end
  end

  # 옵션 2: Registry Pattern (더 명시적)
  # app/models/site.rb
  CLIENT_REGISTRY = {
    rss: ->(site) { RssClient.new(base_uri: site.base_uri) },
    rss_page: ->(site) { RssClient.new(base_uri: site.base_uri) },
    gmail: ->(site) { Gmail.new },
    youtube: ->(site) {
      return nil if site.channel.blank?
      Youtube::Channel.new(id: site.channel)
    },
    hacker_news: ->(site) { HackerNews.new }
  }.freeze

  def init_client
    factory = CLIENT_REGISTRY[client.to_sym]
    raise ArgumentError, "Unknown client: #{client}" unless factory

    factory.call(self)
  end
  ```

#### ℹ️ **Medium Severity Issues**

**MED-MOD-01: Comment 모델 - MAX_DEPTH 미검증**
- **위치**: `app/models/comment.rb`
- **문제**:
  - `MAX_BODY_LENGTH` 상수는 있지만 사용되지 않음 (validation에서 하드코딩)
  - `MAX_DEPTH` 상수는 정의되지 않음 (AGENTS.md에 언급)
- **권장사항**:
  ```ruby
  class Comment < ApplicationRecord
    acts_as_nested_set

    MAX_BODY_LENGTH = 1000
    MAX_DEPTH = 5

    validates :body, presence: true, length: { maximum: MAX_BODY_LENGTH }
    validate :depth_within_limit

    private

    def depth_within_limit
      return unless parent_id

      if level >= MAX_DEPTH
        errors.add(:base, "댓글 중첩은 #{MAX_DEPTH}단계까지만 가능합니다")
      end
    end
  end
  ```

---

### 4️⃣ Controllers (컨트롤러)

#### ⚠️ **High Severity Issues**

**HIGH-CTRL-01: ArticlesController#index - 복잡한 조건부 로직**
- **위치**: `app/controllers/articles_controller.rb:13-28`
- **문제**:
  ```ruby
  def index
    scope = Article.kept.confirmed

    article = if params[:search].present?
      scope.full_text_search_for(params[:search])
    else
      scope = scope.related
      article_count = scope.where(created_at: 24.hours.ago...).count
      id = if article_count < 9
        scope.select(:id).limit(9).order(created_at: :desc).map(&:id)
      else
        scope.select(:id).where(created_at: 24.hours.ago...).map(&:id)
      end
      scope.where.not(id: id)
    end
    @pagy, @articles = pagy(article.includes(:user, :site).order(published_at: :desc))
  end
  ```
- **Code Smell**: Long Method, Feature Envy
- **영향**: 테스트 어려움, 가독성 저하
- **권장사항**: **Extract Query Object**
  ```ruby
  # app/models/article_search.rb
  class ArticleSearch
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :query, :string
    attribute :exclude_recent, :boolean, default: true

    def results
      scope = Article.kept.confirmed

      if query.present?
        scope.full_text_search_for(query)
      else
        recent_articles_excluded(scope.related)
      end
    end

    private

    def recent_articles_excluded(scope)
      recent_scope = scope.where(created_at: 24.hours.ago...)
      recent_count = recent_scope.count

      excluded_ids = if recent_count < 9
        scope.select(:id).limit(9).order(created_at: :desc).pluck(:id)
      else
        recent_scope.select(:id).order(created_at: :desc).pluck(:id)
      end

      scope.where.not(id: excluded_ids)
    end
  end

  # app/controllers/articles_controller.rb
  def index
    search = ArticleSearch.new(query: params[:search])
    @pagy, @articles = pagy(
      search.results.includes(:user, :site).order(published_at: :desc)
    )
  end
  ```

#### ℹ️ **Medium Severity Issues**

**MED-CTRL-01: 에러 핸들링 불일치**
- **위치**: `app/controllers/articles_controller.rb:66-72`
- **문제**: 중복 URL 에러 처리가 복잡함
  ```ruby
  if @article.errors.details[:origin_url].any? { |e| e[:error] == :taken } &&
     @article.errors.details[:url].any? { |e| e[:error] == :taken }
    existing_article = Article.where(url: @article.url)
                              .or(Article.where(origin_url: @article.origin_url))
                              .first
    format.html { redirect_to article_path(existing_article) }
  ```
- **권장사항**: Custom Validator로 추출
  ```ruby
  # app/validators/unique_article_url_validator.rb
  class UniqueArticleUrlValidator < ActiveModel::Validator
    def validate(record)
      return if record.persisted?

      existing = Article.where(url: record.url)
                       .or(Article.where(origin_url: record.origin_url))
                       .first

      if existing
        record.errors.add(:base, :duplicate_article, article: existing)
      end
    end
  end

  # app/models/article.rb
  validates_with UniqueArticleUrlValidator

  # app/controllers/articles_controller.rb
  def create
    if @article.save
      ArticleJob.perform_later(@article.id)
      redirect_to article_path(@article)
    elsif (duplicate = @article.errors.details[:base].find { |e| e[:error] == :duplicate_article })
      redirect_to article_path(duplicate[:article])
    else
      render :new, status: :unprocessable_entity
    end
  end
  ```

---

### 5️⃣ Code Design (아키텍처 & 디자인)

#### ✅ **Excellent Practices**

**GOOD-DESIGN-01: Dry::Operation 패턴 우수**
- **위치**: `app/services/social_media_service.rb`, `app/services/content_service.rb`
- **강점**:
  - Railway-Oriented Programming으로 명시적 에러 핸들링
  - `Success`/`Failure` 모나드로 결과 타입 명확
  - 상속 구조로 플랫폼별 차이 추상화
  - Step-by-step validation 체인
- **예시**:
  ```ruby
  class SocialMediaService < Dry::Operation
    def call(article, command: :post)
      case command
      when :post
        step should_post_article?(article)
        step post_to_platform(article)  # 자식 클래스 구현
      when :delete
        step delete_from_platform(article)
      end
    end
  end

  # 사용
  result = TwitterService.new.call(article)
  if result.success?
    twitter_id = result.value!
  else
    error_type = result.failure  # :not_suitable, :already_posted 등
  end
  ```

**GOOD-DESIGN-02: ApplicationClient 표준화**
- **위치**: `app/clients/application_client.rb`
- **강점**:
  - 일관된 HTTP 클라이언트 인터페이스
  - 표준화된 에러 클래스 (`Forbidden`, `RateLimit`, `NotFound`)
  - Retry 미들웨어 자동 적용
  - Timeout 설정 일관성
  - Authorization header 추상화

**GOOD-DESIGN-03: RBS Inline 적극 활용**
- **모든 주요 파일**에서 타입 어노테이션 사용
- 예시:
  ```ruby
  # rbs_inline: enabled

  def youtube_id #: String?
    # 구현
  end

  def call(article) #: void
    # 구현
  end
  ```
- **장점**: Steep을 통한 정적 타입 검증 가능

#### ⚠️ **High Severity Issues**

**HIGH-DESIGN-01: Service Object 네이밍 개선 필요**
- **위치**: `app/services/`
- **문제**: thoughtbot PORO 패턴과 불일치
- **현황**:
  ```
  ❌ ArticleLlmService       → 권장: Articles::LlmProcessor 또는 Articles::AiSummarizer
  ❌ ContentService          → 권장: Articles::ContentFetcher
  ❌ OauthClientService      → 권장: OauthClientBuilder
  ❌ SitemapService          → 권장: SitemapGenerator (이미 gem 이름과 충돌)
  ✅ TwitterService          → 허용 (Dry::Operation 기반 + 상속 구조)
  ✅ MastodonService         → 허용 (동일)
  ✅ SocialMediaService      → 허용 (추상 클래스)
  ```
- **권장사항**:
  ```ruby
  # Before: app/services/article_llm_service.rb
  class ArticleLlmService < ApplicationService
    def initialize(article)
      @article = article
    end

    def call
      # AI 요약 로직
    end
  end

  # After: app/models/articles/ai_summarizer.rb
  module Articles
    class AiSummarizer
      include ActiveModel::Model

      attr_accessor :article

      def summarize
        return unless article.body.present?

        chat = build_llm_chat
        response = chat.ask(build_prompt)

        update_article_with_summary(response)
      end

      private

      def build_llm_chat
        RubyLLM.chat(model: "gemini-2.5-flash", provider: :gemini)
               .with_temperature(0.6)
               .with_schema(ArticleSchema)
      end

      def build_prompt
        type = article.is_youtube? ? "YoutubeContent" : "HtmlContent"
        "#{type}로 제공한 url과 #{PROMPT}"
      end
    end
  end

  # 사용
  # app/jobs/article_job.rb
  def perform(id)
    article = Article.find(id)
    Articles::AiSummarizer.new(article: article).summarize
  end
  ```

**HIGH-DESIGN-02: ApplicationService 패턴 불명확**
- **위치**: `app/services/application_service.rb`
- **문제**:
  - `include ActiveModel::Model`이지만 속성 없음
  - `.call` 클래스 메서드와 `#call` 인스턴스 메서드 혼용
  - PORO 패턴과 Service Object 패턴 혼재
- **권장사항**: 두 패턴 중 하나로 통일

  **옵션 1: ApplicationService 제거, PORO로 전환**
  ```ruby
  # ApplicationService 삭제

  # app/models/articles/ai_summarizer.rb
  module Articles
    class AiSummarizer
      include ActiveModel::Model

      attr_accessor :article

      validates :article, presence: true

      def summarize
        return false unless valid?
        # 구현
        true
      end
    end
  end
  ```

  **옵션 2: ApplicationOperation으로 통일 (Dry::Operation 기반)**
  ```ruby
  # app/services/application_operation.rb
  class ApplicationOperation < Dry::Operation
    def logger
      Rails.logger
    end
  end

  # 모든 Service를 Operation으로 변경
  class Articles::AiProcessor < ApplicationOperation
    def call(article)
      step validate_article(article)
      step fetch_content(article)
      step process_with_llm(article)
    end
  end
  ```

#### ℹ️ **Medium Severity Issues**

**MED-DESIGN-01: 디렉토리 구조 일관성 부족**
- **문제**:
  - `app/services/` - Service Objects
  - `app/clients/` - API Clients
  - `app/models/` - ActiveRecord + 도메인 로직 혼재
- **권장사항**: thoughtbot 패턴 따라 `app/models/` 중심 구조
  ```
  app/models/
  ├── article.rb
  ├── articles/
  │   ├── ai_summarizer.rb       # LLM 처리
  │   ├── content_fetcher.rb     # 콘텐츠 가져오기
  │   ├── url_processor.rb       # URL 정규화
  │   ├── youtube_handler.rb     # YouTube 처리
  │   └── metadata_extractor.rb  # 메타데이터 추출
  ├── sites/
  │   └── client_factory.rb      # Site#init_client 로직
  └── social_media/
      ├── twitter_poster.rb
      └── mastodon_poster.rb

  app/clients/  # 외부 API 클라이언트만 유지
  ├── application_client.rb
  ├── twitter_client.rb
  ├── mastodon_client.rb
  └── ...
  ```

---

### 6️⃣ Views & Presenters (뷰)

#### ℹ️ **Info**

**현황**: 이번 감사에서는 뷰 파일을 상세 분석하지 않았으나, Hotwire (Turbo/Stimulus) 사용 확인됨.

**권장사항**:
- 뷰 로직이 복잡해지면 Presenter 패턴 도입 검토
- 예시:
  ```ruby
  # app/models/article_presenter.rb
  class ArticlePresenter
    def initialize(article)
      @article = article
    end

    def display_title
      @article.title_ko.presence || @article.title
    end

    def formatted_published_date
      I18n.l(@article.published_at, format: :short)
    end

    def summary_text
      @article.summary_key&.first || "요약 정보가 없습니다."
    end
  end

  # app/controllers/articles_controller.rb
  def show
    @presenter = ArticlePresenter.new(@article)
  end

  # app/views/articles/show.html.erb
  <%= @presenter.display_title %>
  ```

---

## 🎯 우선순위별 권장사항

### 🔴 즉시 조치 (Critical - 1-2주 내)

1. **Job 테스트 추가** (CRIT-TEST-01)
   - 최소한 `ArticleJob`, `SocialPostJob` 테스트 작성
   - 예상 시간: 4-8시간

2. **Article 모델 리팩토링 착수** (CRIT-MOD-01)
   - Phase 1: URL/YouTube 처리 추출 (8시간)
   - Phase 2: 콜백 제거 (4시간)

### 🟠 단기 조치 (High - 1개월 내)

3. **컨트롤러 테스트 추가** (CRIT-TEST-02)
   - `ArticlesController`, `CommentsController` 우선
   - 예상 시간: 8-12시간

4. **클라이언트 테스트 추가** (CRIT-TEST-03)
   - WebMock/VCR 설정
   - `TwitterClient`, `MastodonClient` 우선
   - 예상 시간: 6-8시간

5. **Service Object 네이밍 개선** (HIGH-DESIGN-01)
   - `ArticleLlmService` → `Articles::AiSummarizer`
   - `ContentService` → `Articles::ContentFetcher`
   - 예상 시간: 4-6시간

6. **Site#init_client 리팩토링** (HIGH-MOD-02)
   - Case statement → Registry Pattern
   - 예상 시간: 2-3시간

### 🟡 중기 조치 (Medium - 2-3개월 내)

7. **ArticlesController#index Query Object 추출** (HIGH-CTRL-01)
   - 예상 시간: 3-4시간

8. **SSRF 방어 강화** (MED-SEC-02)
   - Private IP 차단
   - 예상 시간: 2시간

9. **Comment 깊이 검증 추가** (MED-MOD-01)
   - 예상 시간: 1-2시간

10. **디렉토리 구조 재구성** (MED-DESIGN-01)
    - `app/services/` → `app/models/` 네임스페이스
    - 예상 시간: 4-6시간

---

## 📈 메트릭 요약

| 카테고리 | 파일 수 | 테스트 파일 | 커버리지 | 상태 |
|---------|---------|------------|---------|------|
| Models | 10 | 7 | 70% | 🟡 양호 |
| Controllers | 16 | 0 | 0% | 🔴 심각 |
| Services | 9 | 7 | 78% | 🟡 양호 |
| Jobs | 9 | 0 | 0% | 🔴 심각 |
| Clients | 8 | 0 | 0% | 🔴 심각 |
| **전체** | **77** | **14** | **~25%** | 🔴 **부족** |

**Code Smells 발견**:
- 🔴 Critical: 3건 (God Class, Callback Complexity, Missing Tests)
- 🟠 High: 6건
- 🟡 Medium: 5건
- 🟢 Low: 0건

**보안 이슈**:
- 🟡 Medium: 2건 (SSRF, Mass Assignment 주의사항)
- ✅ Critical/High: 없음

---

## ✅ 모범 사례 (Best Practices Found)

1. **RBS Inline 타입 어노테이션** - 정적 타입 검증 가능
2. **Dry::Operation Railway Pattern** - 명시적 에러 핸들링
3. **Article 모델 테스트 품질** - 637줄, 엣지 케이스 포괄
4. **Soft Delete 일관적 적용** - Discard gem
5. **ApplicationClient 표준화** - 외부 API 클라이언트 일관성
6. **한국어 지원** - i18n, Korean dictionary, 시간대 처리
7. **벡터 검색** - pgvector 활용한 유사 기사 추천

---

## 📚 참고 자료

- [Ruby Science](https://github.com/thoughtbot/ruby-science) - Code Smells & Refactoring
- [Testing Rails](https://github.com/thoughtbot/testing-rails) - 테스트 모범 사례
- [Rails 8 Guides](https://guides.rubyonrails.org/) - 최신 패턴
- [Dry-rb](https://dry-rb.org/) - Railway-Oriented Programming

---

## 📝 다음 단계

1. ✅ 이 보고서를 팀과 공유하고 우선순위 합의
2. 🎯 Sprint Planning에 Critical 항목 포함
3. 📊 테스트 커버리지 목표 설정 (최소 60% 목표)
4. 🔄 주간 코드 리뷰에서 Code Smell 체크리스트 적용
5. 📈 SimpleCov 도입하여 커버리지 측정 자동화

---

**감사 완료일**: 2026-01-22
**다음 감사 권장일**: 2026-04-22 (3개월 후)
