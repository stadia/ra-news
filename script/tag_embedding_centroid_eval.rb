#!/usr/bin/env ruby
# frozen_string_literal: true

# 태그별 기사 embedding centroid를 계산하고,
# centroid 기준 nearest neighbor(상위 50개)를 CSV로 출력하는 평가용 스크립트
#
# 사용법:
#   bin/rails runner script/tag_embedding_centroid_eval.rb
#
# 출력:
#   tmp/tag_centroid_eval/{태그명}_centroid_neighbors.csv
#   tmp/tag_centroid_eval/summary.csv

require "csv"
require "fileutils"

OUTPUT_DIR = Rails.root.join("tmp", "tag_centroid_eval")
TOP_K = 50

FileUtils.mkdir_p(OUTPUT_DIR)

# 기본 URL 헬퍼를 위해 default_url_options 설정 (미설정 시 fallback)
Rails.application.routes.default_url_options ||= { host: "localhost", port: 3000 }

confirmed_tags = ActsAsTaggableOn::Tag.where(is_confirmed: true).order(:name)
total = confirmed_tags.count
puts "총 #{total}개의 확정 태그를 처리합니다.\n\n"

summary_rows = []

confirmed_tags.find_each.with_index(1) do |tag, idx|
  puts "[#{idx}/#{total}] 태그: #{tag.name}"

  # 1) centroid 계산 — 해당 태그가 붙은 kept 기사들의 embedding 평균
  centroid_sql = <<~SQL.squish
    SELECT AVG(articles.embedding)::text AS centroid,
           COUNT(articles.id)            AS article_count
    FROM articles
    INNER JOIN taggings
      ON taggings.taggable_id = articles.id
      AND taggings.taggable_type = 'Article'
    WHERE taggings.tag_id = #{tag.id}
      AND articles.embedding IS NOT NULL
      AND articles.deleted_at IS NULL
  SQL

  result = ActiveRecord::Base.connection.select_one(centroid_sql)
  centroid_str = result["centroid"]
  article_count = result["article_count"].to_i

  if centroid_str.blank? || article_count == 0
    puts "   → embedding이 있는 기사가 없어 건너뜁니다."
    summary_rows << [ tag.name, article_count, 0, "skipped" ]
    next
  end

  # PostgreSQL vector text 표현 "{0.1,0.2,...}" → Ruby Array
  centroid_arr = centroid_str.delete("{}").split(",").map(&:to_f)

  puts "   → 기사 #{article_count}개로 centroid 계산 완료 (#{centroid_arr.size}차원)"

  # 2) centroid 기준 nearest neighbor 검색 (유클리드 거리)
  # .count를 Relation에 직접 호출하면 neighbor_distance 컬럼 별칭과 충돌하므로
  # .to_a로 평가한 뒤 size를 사용합니다.
  neighbors = Article
    .kept
    .where.not(embedding: nil)
    .nearest_neighbors(:embedding, centroid_arr, distance: "euclidean")
    .limit(TOP_K)
    .to_a

  # 3) 태그별 CSV 저장
  safe_tag_name = tag.name.parameterize.presence || "tag-#{tag.id}"
  csv_path = OUTPUT_DIR.join("#{safe_tag_name}_centroid_neighbors.csv")

  CSV.open(csv_path, "w") do |csv|
    csv << %w[rank article_id title title_ko distance tag_names url]
    neighbors.each_with_index do |article, ridx|
      csv << [
        ridx + 1,
        article.id,
        article.title,
        article.title_ko,
        article.neighbor_distance,
        article.tag_list.join(", "),
        Rails.application.routes.url_helpers.article_url(article)
      ]
    end
  end

  neighbor_count = neighbors.size
  puts "   → 상위 #{neighbor_count}개 결과 저장: #{csv_path}"
  summary_rows << [ tag.name, article_count, neighbor_count, csv_path.relative_path_from(Rails.root) ]
end

# 4) 요약 CSV
summary_path = OUTPUT_DIR.join("summary.csv")
CSV.open(summary_path, "w") do |csv|
  csv << %w[tag_name article_count neighbor_count status_or_path]
  summary_rows.each { |row| csv << row }
end

puts "\n==================================="
puts "평가 결과가 저장되었습니다: #{OUTPUT_DIR}"
puts "요약 파일: #{summary_path}"
puts "==================================="
