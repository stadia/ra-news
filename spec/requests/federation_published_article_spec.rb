# frozen_string_literal: true

require "rails_helper"

# federails published 엔드포인트는 should_federate? 인 기사를 ActivityPub Note 로
# 직렬화한다. 과거에 federails_actor_id 컬럼이 비워진 채 생성된 기사(대부분)는
# 봇 user 의 actor 로 폴백해야 하며, 폴백이 없으면 직렬화 중
# `federails_actor.federated_url` 호출에서 NoMethodError(500)가 발생했다.
RSpec.describe "Federation published articles", type: :request do
  fixtures :articles, :users, :federails_actors, :sites, :roles

  # user: john(봇) + title_ko 존재 + federails_actor_id 미설정 → 실제 장애 재현 조건
  let(:article) { articles(:ruby_article) }

  it "federails_actor 컬럼이 비어 있어도 봇 actor 로 직렬화한다" do
    expect(article.federails_actor_id).to be_nil
    expect(article.should_federate?).to be(true)

    host! "ruby-news.dev"
    get "/federation/published/articles/#{article.id}",
        headers: { "Accept" => "application/activity+json" }

    expect(response).to have_http_status(:ok)

    body = JSON.parse(response.body)
    bot_actor_url = User.first_bot.federails_actor.federated_url
    expect(body["attributedTo"]).to eq(bot_actor_url)
    expect(body["actor"]).to eq(bot_actor_url)
  end
end
