# frozen_string_literal: true

class CreateSlackCredentials < ActiveRecord::Migration[8.0]
  def change
    create_table :slack_credentials do |t|
      t.references :user, null: false, foreign_key: true, comment: "사용자 ID"

      # Slack OAuth 토큰 정보 (암호화됨)
      t.text :access_token, null: false, comment: "액세스 토큰 (암호화)"
      t.text :refresh_token, comment: "리프레시 토큰 (암호화)"

      # 토큰 메타데이터
      t.datetime :expires_at, comment: "토큰 만료 시각"
      t.datetime :token_created_at, null: false, comment: "토큰 발급 시각"

      # Slack 팀 정보
      t.string :team_id, null: false, comment: "Slack 팀 ID"
      t.string :team_name, null: false, comment: "Slack 팀 이름"

      # 추가 메타데이터
      t.string :scope, comment: "승인된 권한 범위"
      t.string :bot_user_id, comment: "봇 사용자 ID"
      t.string :webhook_url, comment: "Incoming Webhook URL"
      t.string :webhook_channel, comment: "Webhook 채널명"

      t.timestamps

      # 인덱스
      t.index [ :user_id, :team_id ], unique: true, name: "index_slack_credentials_on_user_and_team"
      t.index :team_id, name: "index_slack_credentials_on_team_id"
      t.index :expires_at, name: "index_slack_credentials_on_expires_at"
    end
  end
end
