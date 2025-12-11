Federails.config_from "federails"

# User 클래스를 로드하여 Federails::Configuration.actor_types를 설정
# acts_as_federails_actor 호출 시 자동으로 register_actor_class가 실행됨
Rails.application.config.after_initialize do
  User # User 클래스를 참조하여 로드
end
