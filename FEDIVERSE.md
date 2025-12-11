# Fediverse와 ActivityPub 구현 가이드

## 1. Fediverse 개요

### Fediverse란?
**Fediverse**(Federated Universe)는 분산형 소셜 네트워크의 집합체입니다. 각 서버(인스턴스)가 독립적으로 운영되면서도 표준화된 프로토콜을 통해 상호 연결되어 하나의 거대한 소셜 네트워크를 형성합니다.

### 주요 특징
- **탈중앙화**: 단일 기업이나 조직이 제어하지 않음
- **상호운용성**: 서로 다른 소프트웨어끼리도 통신 가능
- **사용자 통제**: 각 사용자가 자신의 데이터와 경험을 제어
- **오픈 소스**: 대부분의 Fediverse 소프트웨어는 오픈 소스

### 주요 플랫폼
- **Mastodon**: 마이크로블로깅 (Twitter 대안)
- **Pixelfed**: 사진 공유 (Instagram 대안)
- **PeerTube**: 동영상 플랫폼 (YouTube 대안)
- **Lemmy**: 링크 공유/토론 (Reddit 대안)
- **WriteFreely**: 블로그 플랫폼

## 2. ActivityPub 프로토콜

### ActivityPub이란?
2018년 1월 W3C가 공식 표준으로 승인한 분산형 소셜 네트워킹 프로토콜입니다. ActivityStreams 2.0 데이터 형식과 JSON-LD를 기반으로 합니다.

### 핵심 구성요소

#### 2.1 데이터 타입
- **Actor(액터)**: 사용자, 그룹, 서비스를 나타내는 주체
- **Activity(액티비티)**: 생성, 수정, 삭제 등의 동작
- **Object(객체)**: 게시물, 이미지, 비디오 등의 콘텐츠

#### 2.2 주요 액티비티 타입
```json
{
  "Create": "콘텐츠 생성",
  "Update": "콘텐츠 수정",
  "Delete": "콘텐츠 삭제",
  "Follow": "팔로우",
  "Like": "좋아요",
  "Announce": "공유/부스트",
  "Block": "차단"
}
```

### 프로토콜 계층

#### Server-to-Server (S2S) - 연합 프로토콜
- 서로 다른 서버 간의 통신
- 액티비티를 다른 서버의 액터 인박스로 전달
- HTTP POST로 JSON-LD 문서 전송
- HTTP Signature를 통한 인증

#### Client-to-Server (C2S) - 클라이언트 API
- 사용자 클라이언트와 서버 간의 통신
- Outbox를 통한 액티비티 발행
- 콘텐츠 생성, 수정, 삭제 지원
- **참고**: Mastodon은 자체 API를 사용하며 C2S를 구현하지 않음

## 3. ActivityPub 구현 필수 요구사항

### 3.1 Actor 문서
모든 사용자/서비스는 Actor 문서를 가져야 합니다:

```json
{
  "@context": [
    "https://www.w3.org/ns/activitystreams",
    "https://w3id.org/security/v1"
  ],
  "id": "https://ruby-news.kr/users/admin",
  "type": "Person",
  "preferredUsername": "admin",
  "inbox": "https://ruby-news.kr/users/admin/inbox",
  "outbox": "https://ruby-news.kr/users/admin/outbox",
  "followers": "https://ruby-news.kr/users/admin/followers",
  "following": "https://ruby-news.kr/users/admin/following",
  "publicKey": {
    "id": "https://ruby-news.kr/users/admin#main-key",
    "owner": "https://ruby-news.kr/users/admin",
    "publicKeyPem": "-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----"
  }
}
```

### 3.2 WebFinger 지원
사용자 검색을 위한 WebFinger 엔드포인트:

```
GET /.well-known/webfinger?resource=acct:admin@ruby-news.kr
```

응답 예시:
```json
{
  "subject": "acct:admin@ruby-news.kr",
  "aliases": ["https://ruby-news.kr/users/admin"],
  "links": [
    {
      "rel": "self",
      "type": "application/activity+json",
      "href": "https://ruby-news.kr/users/admin"
    }
  ]
}
```

### 3.3 HTTP Signatures
모든 서버 간 요청은 암호화 서명이 필요합니다:

```ruby
# 서명 헤더 예시
Signature: keyId="https://ruby-news.kr/users/admin#main-key",
  algorithm="rsa-sha256",
  headers="(request-target) host date digest content-type",
  signature="Base64EncodedSignature=="
```

### 3.4 Content Negotiation
ActivityPub 요청은 올바른 Accept 헤더가 필요합니다:

```
Accept: application/activity+json
```

또는:
```
Accept: application/ld+json; profile="https://www.w3.org/ns/activitystreams"
```

## 4. Rails 구현 방법

### 4.1 사용 가능한 Ruby/Rails 라이브러리

#### Federails (추천)
```ruby
# Gemfile
gem 'federails'

# 설치
bundle install
rails federails:install
rails db:migrate
```

GitLab: https://gitlab.com/experimentslabs/federails
- Rails 엔진 형태로 제공
- ActivityPub 기능을 기존 Rails 앱에 추가
- MIT 라이선스

#### rauversion/activitypub
```ruby
gem 'activitypub'
```

GitHub: https://github.com/rauversion/activitypub
- ActivityPub 객체 생성 및 관리
- Outbox/Inbox 기능
- 서명 검증 지원

#### activity_pub_app
GitHub: https://github.com/mbajur/activity_pub_app
- 완전한 Rails 엔진 솔루션
- UI 엔진 포함
- 기존 Rails 프로젝트에 추가 가능

### 4.2 직접 구현 시 필수 컴포넌트

#### 4.2.1 모델 구조
```ruby
# app/models/actor.rb
class Actor < ApplicationRecord
  # 액터 정보 (User, Application 등)
  has_one :keypair
  has_many :activities
  has_many :followers
  has_many :following
  
  def inbox_url
    Rails.application.routes.url_helpers.user_inbox_url(self)
  end
  
  def outbox_url
    Rails.application.routes.url_helpers.user_outbox_url(self)
  end
end

# app/models/activity.rb
class Activity < ApplicationRecord
  # ActivityPub 액티비티 저장
  belongs_to :actor
  belongs_to :object, polymorphic: true
  
  # type: Create, Update, Delete, Follow, Like, Announce
end

# app/models/keypair.rb
class Keypair < ApplicationRecord
  # RSA 키 쌍 저장
  belongs_to :actor
  
  def generate_keys
    key = OpenSSL::PKey::RSA.new(2048)
    self.private_key = key.to_pem
    self.public_key = key.public_key.to_pem
  end
end
```

#### 4.2.2 라우팅 설정
```ruby
# config/routes.rb
Rails.application.routes.draw do
  # WebFinger
  get '/.well-known/webfinger', to: 'webfinger#show'
  
  # Actor 엔드포인트
  resources :users, only: [:show] do
    member do
      get :inbox, to: 'inboxes#show'
      post :inbox, to: 'inboxes#create'
      get :outbox, to: 'outboxes#show'
      get :followers
      get :following
    end
  end
end
```

#### 4.2.3 컨트롤러 구현
```ruby
# app/controllers/users_controller.rb
class UsersController < ApplicationController
  before_action :set_content_type
  
  def show
    @user = User.find_by!(username: params[:id])
    
    render json: {
      "@context": ["https://www.w3.org/ns/activitystreams", "https://w3id.org/security/v1"],
      "id": user_url(@user),
      "type": "Person",
      "preferredUsername": @user.username,
      "inbox": user_inbox_url(@user),
      "outbox": user_outbox_url(@user),
      "publicKey": {
        "id": "#{user_url(@user)}#main-key",
        "owner": user_url(@user),
        "publicKeyPem": @user.keypair.public_key
      }
    }
  end
  
  private
  
  def set_content_type
    response.headers['Content-Type'] = 'application/activity+json; charset=utf-8'
  end
end

# app/controllers/inboxes_controller.rb
class InboxesController < ApplicationController
  before_action :verify_signature
  
  def create
    @user = User.find_by!(username: params[:user_id])
    activity = JSON.parse(request.body.read)
    
    # 액티비티 처리
    ActivityProcessor.process(@user, activity)
    
    head :accepted
  end
  
  private
  
  def verify_signature
    # HTTP Signature 검증
    # 구현 필요
  end
end

# app/controllers/webfinger_controller.rb
class WebfingerController < ApplicationController
  def show
    resource = params[:resource] # acct:username@domain
    username = resource.split('@')[1] if resource.start_with?('acct:')
    
    @user = User.find_by!(username: username)
    
    render json: {
      subject: resource,
      aliases: [user_url(@user)],
      links: [
        {
          rel: "self",
          type: "application/activity+json",
          href: user_url(@user)
        }
      ]
    }
  end
end
```

#### 4.2.4 서비스 객체
```ruby
# app/services/activity_processor.rb
class ActivityProcessor
  def self.process(actor, activity)
    case activity['type']
    when 'Follow'
      process_follow(actor, activity)
    when 'Create'
      process_create(actor, activity)
    when 'Like'
      process_like(actor, activity)
    when 'Announce'
      process_announce(actor, activity)
    end
  end
  
  def self.process_follow(actor, activity)
    follower_id = activity['actor']
    # 팔로워 추가 로직
  end
  
  # 기타 처리 메서드...
end

# app/services/activity_sender.rb
class ActivitySender
  def self.send_activity(from_actor, to_inbox_url, activity)
    # HTTP Signature 생성
    signature = generate_signature(from_actor, to_inbox_url, activity)
    
    # POST 요청
    HTTParty.post(
      to_inbox_url,
      body: activity.to_json,
      headers: {
        'Content-Type': 'application/activity+json',
        'Signature': signature
      }
    )
  end
  
  def self.generate_signature(actor, url, body)
    # RSA 서명 생성
    # 구현 필요
  end
end
```

#### 4.2.5 HTTP Signature 구현
```ruby
# app/services/http_signature.rb
class HttpSignature
  def self.sign(private_key, key_id, method, path, headers, body = nil)
    # Digest 계산 (body가 있는 경우)
    if body
      digest = Digest::SHA256.base64digest(body)
      headers['Digest'] = "SHA-256=#{digest}"
    end
    
    # 서명할 문자열 구성
    signature_string = [
      "(request-target): #{method.downcase} #{path}",
      "host: #{headers['Host']}",
      "date: #{headers['Date']}",
      body ? "digest: #{headers['Digest']}" : nil
    ].compact.join("\n")
    
    # RSA 서명
    private_key = OpenSSL::PKey::RSA.new(private_key)
    signature = Base64.strict_encode64(private_key.sign(OpenSSL::Digest::SHA256.new, signature_string))
    
    # Signature 헤더 구성
    header_names = ["(request-target)", "host", "date"]
    header_names << "digest" if body
    
    "keyId=\"#{key_id}\",algorithm=\"rsa-sha256\",headers=\"#{header_names.join(' ')}\",signature=\"#{signature}\""
  end
  
  def self.verify(public_key, signature_header, request)
    # 서명 검증 로직
    # 구현 필요
  end
end
```

### 4.3 Ruby-News에 적용 시 고려사항

#### 4.3.1 기존 모델 확장
```ruby
# app/models/user.rb
class User < ApplicationRecord
  # 기존 코드...
  
  # ActivityPub 관련 추가
  has_one :actor_profile
  delegate :inbox_url, :outbox_url, :actor_url, to: :actor_profile
  
  after_create :create_actor_profile
  
  def to_activitypub
    {
      "@context": "https://www.w3.org/ns/activitystreams",
      "id": actor_url,
      "type": "Person",
      "preferredUsername": username,
      "inbox": inbox_url,
      "outbox": outbox_url
    }
  end
end

# app/models/article.rb
class Article < ApplicationRecord
  # 기존 코드...
  
  def to_activitypub
    {
      "type": "Article",
      "id": article_url(self),
      "published": created_at.iso8601,
      "attributedTo": user.actor_url,
      "name": title,
      "content": body_html,
      "url": article_url(self),
      "tag": tags.map { |t| { "type": "Hashtag", "name": "##{t.name}" } }
    }
  end
end
```

#### 4.3.2 백그라운드 작업
```ruby
# app/jobs/activity_delivery_job.rb
class ActivityDeliveryJob < ApplicationJob
  queue_as :default
  
  def perform(activity_id)
    activity = Activity.find(activity_id)
    
    # 팔로워들의 inbox로 전송
    activity.actor.followers.each do |follower|
      ActivitySender.send_activity(
        activity.actor,
        follower.inbox_url,
        activity.to_json
      )
    end
  end
end

# app/jobs/remote_fetch_job.rb
class RemoteFetchJob < ApplicationJob
  queue_as :default
  
  def perform(object_url)
    # 원격 객체 가져오기
    response = HTTParty.get(
      object_url,
      headers: { 'Accept': 'application/activity+json' }
    )
    
    # 로컬 데이터베이스에 저장
    RemoteObject.create_from_activitypub(response.parsed_response)
  end
end
```

#### 4.3.3 보안 고려사항
```ruby
# app/controllers/concerns/activitypub_security.rb
module ActivitypubSecurity
  extend ActiveSupport::Concern
  
  included do
    before_action :verify_activitypub_signature, if: :activitypub_request?
  end
  
  private
  
  def activitypub_request?
    request.content_type == 'application/activity+json'
  end
  
  def verify_activitypub_signature
    signature = request.headers['Signature']
    return head :unauthorized unless signature
    
    # 서명 파싱 및 검증
    unless HttpSignature.verify(signature, request)
      head :unauthorized
    end
  end
  
  def rate_limit_check
    # 속도 제한 구현
    throttle("inbox/#{request.remote_ip}", limit: 100, period: 1.hour) do
      head :too_many_requests
    end
  end
end
```

## 5. 구현 단계별 로드맵

### Phase 1: 기본 인프라 (2-3주)
- [ ] WebFinger 엔드포인트 구현
- [ ] Actor 문서 생성 및 제공
- [ ] RSA 키 쌍 생성 및 관리
- [ ] HTTP Signature 서명/검증

### Phase 2: 읽기 연합 (2-3주)
- [ ] Inbox 엔드포인트 구현
- [ ] 원격 액티비티 수신 및 처리
- [ ] Follow/Unfollow 처리
- [ ] 원격 프로필 검색 및 표시

### Phase 3: 쓰기 연합 (3-4주)
- [ ] Outbox 엔드포인트 구현
- [ ] Article 발행 시 Create 액티비티 전송
- [ ] Like/Announce 액티비티 전송
- [ ] 원격 서버로 액티비티 전달

### Phase 4: 고급 기능 (3-4주)
- [ ] 댓글 연합 (Comment 지원)
- [ ] 원격 검색 기능
- [ ] 타임라인 통합
- [ ] 이미지 첨부 지원

### Phase 5: 최적화 및 보안 (2주)
- [ ] 캐싱 전략
- [ ] 속도 제한
- [ ] 스팸 필터링
- [ ] 관리자 도구

## 6. 테스트 전략

### 6.1 로컬 테스트
```ruby
# test/controllers/webfinger_controller_test.rb
class WebfingerControllerTest < ActionDispatch::IntegrationTest
  test "should return webfinger response" do
    user = users(:one)
    get webfinger_url, params: { resource: "acct:#{user.username}@example.com" }
    
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "acct:#{user.username}@example.com", json['subject']
  end
end

# test/services/http_signature_test.rb
class HttpSignatureTest < ActiveSupport::TestCase
  test "should sign and verify" do
    keypair = Keypair.create_with_keys
    signature = HttpSignature.sign(...)
    
    assert HttpSignature.verify(keypair.public_key, signature, request)
  end
end
```

### 6.2 연합 테스트
- Mastodon 테스트 인스턴스와 연결
- ActivityPub.rocks validator 사용
- 실제 Fediverse 네트워크에서 테스트

## 7. 참고 자료

### 공식 문서
- [ActivityPub W3C Specification](https://www.w3.org/TR/activitypub/)
- [ActivityStreams 2.0](https://www.w3.org/TR/activitystreams-core/)
- [Mastodon ActivityPub Documentation](https://docs.joinmastodon.org/spec/activitypub/)

### 구현 가이드
- [How to implement a basic ActivityPub server](https://blog.joinmastodon.org/2018/06/how-to-implement-a-basic-activitypub-server/)
- [A Developer's Guide to ActivityPub and the Fediverse](https://thenewstack.io/a-developers-guide-to-activitypub-and-the-fediverse/)
- [Guide for new ActivityPub implementers](https://socialhub.activitypub.rocks/t/guide-for-new-activitypub-implementers/479)

### 도구 및 라이브러리
- [Federails](https://gitlab.com/experimentslabs/federails) - Rails ActivityPub 엔진
- [activitypub gem](https://github.com/rauversion/activitypub) - Ruby ActivityPub 라이브러리
- [activity_pub_app](https://github.com/mbajur/activity_pub_app) - Rails 엔진

### 커뮤니티
- [SocialHub](https://socialhub.activitypub.rocks/) - ActivityPub 개발자 포럼
- [Fediverse Developer Resources](https://codeberg.org/fediverse/delightful-activitypub-development)

## 8. 결론

ActivityPub을 Ruby-News에 구현하면:

### 장점
- Ruby 뉴스를 Mastodon 등 Fediverse에서 직접 팔로우 가능
- 탈중앙화된 소셜 미디어 생태계 참여
- 사용자들이 자신의 Fediverse 계정으로 상호작용
- 콘텐츠의 더 넓은 배포

### 도전 과제
- 복잡한 프로토콜 구현
- 보안 및 스팸 관리
- 성능 최적화 필요
- 지속적인 유지보수

### 추천 접근법
1. **초기**: Federails 같은 기존 라이브러리로 시작
2. **중기**: 필요에 따라 커스터마이징
3. **장기**: 자체 구현으로 전환 (필요 시)

ActivityPub 구현은 Ruby-News를 진정한 탈중앙화 플랫폼으로 만들어줄 것입니다.
