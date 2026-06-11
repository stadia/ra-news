# frozen_string_literal: true

namespace :articles do
  desc "기사 임베딩을 현재 모델로 재생성 (배치 단위로 ArticleReembedJob enqueue). " \
       "옵션: ONLY_MISSING=true(임베딩 없는 것만) BATCH_SIZE=50 DRY_RUN=true"
  task reembed: :environment do
    boolean = ActiveModel::Type::Boolean.new
    only_missing = boolean.cast(ENV["ONLY_MISSING"])
    dry_run = boolean.cast(ENV["DRY_RUN"])
    batch_size = (ENV["BATCH_SIZE"].presence || 50).to_i

    scope = Article.kept.where.not(body: nil)
    scope = scope.where(embedding: nil) if only_missing

    total = scope.count
    puts "재임베딩 대상: #{total} articles " \
         "(only_missing=#{!!only_missing}, batch_size=#{batch_size}, " \
         "model=#{Articles::HybridSearch::EMBED_MODEL}/#{Articles::HybridSearch::EMBED_DIMENSIONS}d)"

    if dry_run
      puts "[DRY_RUN] enqueue 생략"
      next
    end

    if total.zero?
      puts "대상 없음. 종료."
      next
    end

    enqueued = 0
    jobs = 0
    scope.in_batches(of: batch_size) do |relation|
      ids = relation.pluck(:id)
      ArticleReembedJob.perform_later(ids)
      enqueued += ids.size
      jobs += 1
    end

    puts "enqueue 완료: #{enqueued} articles / #{jobs} jobs"
  end
end
