# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create Admin User
user = User.find_or_create_by!(email_address: "admin@example.com") do |u|
  u.password = "admin123"
  u.name = "Admin"
end

puts "User created: #{user.name}"

# Mock Articles Data
mock_articles = [
  {
    title: "Rails 8.0.0.beta1 Released: The Future of Web Development",
    title_ko: "Rails 8.0.0.beta1 출시: 웹 개발의 미래",
    url: "https://rubyonrails.org/2025/11/15/rails-8-0-0-beta1",
    host: "rubyonrails.org",
    summary_key: "Rails 8 introduces Solid Queue, Solid Cache, and Solid Cable as defaults, removing the need for Redis. It also includes Kamal 2 for easy deployment.",
    published_at: 2.hours.ago,
    tags: ["Rails", "Release", "Kamal"]
  },
  {
    title: "Ruby 3.4 Adds Pipe Operator for Better Functional Programming",
    title_ko: "Ruby 3.4, 함수형 프로그래밍을 위한 파이프 연산자 추가",
    url: "https://ruby-lang.org/en/news/2025/10/20/ruby-3-4-pipe-operator",
    host: "ruby-lang.org",
    summary_key: "The new pipe operator (|>) allows for cleaner method chaining and functional programming patterns in Ruby, inspired by Elixir.",
    published_at: 5.hours.ago,
    tags: ["Ruby", "Language"]
  },
  {
    title: "Hotwire vs React: Why We Switched Back to Rails",
    title_ko: "Hotwire 대 React: 우리가 다시 Rails로 돌아온 이유",
    url: "https://37signals.com/posts/hotwire-vs-react",
    host: "37signals.com",
    summary_key: "A detailed case study on how switching from a complex React SPA to Rails + Hotwire reduced code size by 40% and improved performance.",
    published_at: 1.day.ago,
    tags: ["Hotwire", "React", "Case Study"]
  },
  {
    title: "Understanding Vector Search in PostgreSQL with pgvector",
    title_ko: "PostgreSQL과 pgvector를 이용한 벡터 검색 이해하기",
    url: "https://pganalyze.com/blog/pgvector-tutorial",
    host: "pganalyze.com",
    summary_key: "Learn how to implement semantic search in your Rails application using PostgreSQL's pgvector extension and OpenAI embeddings.",
    published_at: 2.days.ago,
    tags: ["PostgreSQL", "AI", "Tutorial"]
  },
  {
    title: "Kamal 2.0: Deploy Rails Apps Anywhere with Ease",
    title_ko: "Kamal 2.0: 어디서나 쉽게 Rails 앱 배포하기",
    url: "https://kamal-deploy.org/news/kamal-2-released",
    host: "kamal-deploy.org",
    summary_key: "Kamal 2.0 brings auto-SSL, zero-downtime deployments, and multi-host support, making it the best tool for deploying Rails apps to VPS.",
    published_at: 3.days.ago,
    tags: ["DevOps", "Kamal", "Deployment"]
  },
  {
    title: "Optimizing Active Record Queries for High Performance",
    title_ko: "고성능을 위한 Active Record 쿼리 최적화",
    url: "https://thoughtbot.com/blog/optimizing-active-record",
    host: "thoughtbot.com",
    summary_key: "Tips and tricks for avoiding N+1 queries, using counter_cache, and leveraging database indexes in Rails applications.",
    published_at: 4.days.ago,
    tags: ["Performance", "ActiveRecord"]
  },
  {
    title: "Building a Real-time Chat App with Action Cable and Solid Cable",
    title_ko: "Action Cable과 Solid Cable로 실시간 채팅 앱 만들기",
    url: "https://evilmartians.com/chronicles/solid-cable-tutorial",
    host: "evilmartians.com",
    summary_key: "A step-by-step guide to building a scalable real-time chat application using the new Solid Cable backend for Action Cable.",
    published_at: 5.days.ago,
    tags: ["Tutorial", "Real-time", "SolidCable"]
  }
]

puts "Creating articles..."

mock_articles.each do |data|
  article = Article.find_or_initialize_by(url: data[:url])
  article.assign_attributes(
    title: data[:title],
    title_ko: data[:title_ko],
    origin_url: data[:url],
    host: data[:host],
    summary_key: data[:summary_key],
    published_at: data[:published_at],
    user: user,
    slug: data[:url].split("/").last.gsub(/[^a-zA-Z0-9\-]/, "") # Simple slug generation
  )
  
  if article.save
    puts "Created: #{article.title}"
    # Add tags if acts_as_taggable_on is set up (it seems to be based on model)
    article.tag_list.add(data[:tags])
    article.save
  else
    puts "Failed to create: #{article.title} - #{article.errors.full_messages.join(', ')}"
  end
end

puts "Seed finished!"
