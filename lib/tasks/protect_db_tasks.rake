task :protect_dev_and_test_db_tasks do
  if Rails.env.development? || Rails.env.test?
    raise "이 환경에서는 해당 데이터베이스 task를 실행할 수 없습니다."
  end
end

task :protect_dev_db_tasks do
  if Rails.env.development?
    raise "이 환경에서는 해당 데이터베이스 task를 실행할 수 없습니다."
  end
end

Rake::Task["db:drop"].enhance([ :protect_dev_db_tasks ])
Rake::Task["db:reset"].enhance([ :protect_dev_and_test_db_tasks ])
Rake::Task["db:environment:set"].enhance([ :protect_dev_and_test_db_tasks ])
Rake::Task["db:prepare"].enhance([ :protect_dev_db_tasks ])
Rake::Task["db:setup"].enhance([ :protect_dev_and_test_db_tasks ])
