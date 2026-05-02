# frozen_string_literal: true

# Mutant fork 프로세스에서 pg 젬 Segmentation Fault를 방지합니다.
# 참조: https://github.com/mbj/mutant/blob/main/docs/hooks.md

hooks.register(:env_infection_post) do
  Rails.application.eager_load!
end

hooks.register(:setup_integration_post) do
  # fork 전에 모든 DB 연결을 완전히 제거합니다.
  ActiveRecord::Base.connection_handler.connection_pool_list.each do |pool|
    pool.disconnect!
  end
  ActiveRecord::Base.remove_connection
end

hooks.register(:mutation_worker_process_start) do |index:|
  # fork 후 새 연결을 설정합니다.
  ActiveRecord::Base.establish_connection
end

hooks.register(:test_worker_process_start) do |index:|
  # fork 후 새 연결을 설정합니다.
  ActiveRecord::Base.establish_connection
end