# frozen_string_literal: true
# rbs_inline: enabled

namespace :thumbnails do
  desc "기존 기사 썸네일의 명명 변형(hero/card)을 미리 생성해 렌더 시 직접 CDN URL을 쓰게 한다. " \
       "옵션: DRY_RUN=true BATCH_SIZE=100"
  task backfill_variants: :environment do
    boolean = ActiveModel::Type::Boolean.new
    dry_run = boolean.cast(ENV["DRY_RUN"])
    batch_size = (ENV["BATCH_SIZE"].presence || 100).to_i
    variant_names = Article::THUMBNAIL_VARIANTS.keys

    scope = Article.joins(:thumbnail_attachment)
    total = scope.count
    puts "썸네일 변형 백필 대상: #{total} articles × #{variant_names.size} variants (#{variant_names.join(', ')})"

    if dry_run
      puts "[DRY_RUN] 처리 생략"
      next
    end

    if total.zero?
      puts "대상 없음. 종료."
      next
    end

    processed = 0
    failed = 0
    scope.with_attached_thumbnail.find_each(batch_size: batch_size) do |article|
      variant_names.each do |name|
        article.thumbnail.variant(name).processed
      end
      processed += 1
      puts "  진행: #{processed}/#{total}" if (processed % batch_size).zero?
    rescue ActiveRecord::ConnectionNotEstablished, ActiveRecord::StatementInvalid
      # 시스템 장애(DB 연결 끊김 등)는 건별 실패로 세지 말고 즉시 중단한다.
      raise
    rescue StandardError => e
      failed += 1
      warn "  실패 article=#{article.id}: #{e.class} - #{e.message}"
    end

    puts "완료: 처리 #{processed} / 실패 #{failed} / 전체 #{total}"
  end
end
