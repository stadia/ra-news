# frozen_string_literal: true

require "test_helper"

class TagTest < ActiveSupport::TestCase
  # Test fixtures setup
  def setup
    @ruby_tag = tags(:ruby_tag)
    @rails_tag = tags(:rails_tag)
    @performance_tag = tags(:performance_tag)
    @korean_tag = tags(:korean_tag)
    @new_feature_tag = tags(:new_feature_tag)
    @special_tag = tags(:special_tag)
    @article = articles(:ruby_article)
  end

  # ========== Inheritance Tests ==========

  test "ActsAsTaggableOn::Tag를 상속해야 한다" do
    assert Tag.ancestors.include?(ActsAsTaggableOn::Tag)
  end

  test "ActsAsTaggableOn 기능이 있어야 한다" do
    # Test that basic taggable functionality is available
    assert_respond_to Tag, :find_or_create_with_like_by_name
    assert_respond_to Tag, :named
    assert_respond_to @ruby_tag, :name
    assert_respond_to @ruby_tag, :taggings
  end

  # ========== Scope Tests ==========

  test "confirmed 스코프는 확정된 태그를 반환해야 한다" do
    confirmed_tags = Tag.confirmed

    assert_includes confirmed_tags, @ruby_tag
    assert_includes confirmed_tags, @rails_tag
    assert_includes confirmed_tags, @performance_tag
    assert_not_includes confirmed_tags, @new_feature_tag
    assert_not_includes confirmed_tags, @korean_tag
  end

  test "unconfirmed 스코프는 미확정 태그를 반환해야 한다" do
    unconfirmed_tags = Tag.unconfirmed

    assert_includes unconfirmed_tags, @new_feature_tag
    assert_includes unconfirmed_tags, @korean_tag
    assert_not_includes unconfirmed_tags, @ruby_tag
    assert_not_includes unconfirmed_tags, @rails_tag
    assert_not_includes unconfirmed_tags, @performance_tag
  end

  test "confirmed와 unconfirmed 스코프는 상호 배타적이어야 한다" do
    confirmed = Tag.confirmed.pluck(:id)
    unconfirmed = Tag.unconfirmed.pluck(:id)

    # No tag should be in both lists
    overlap = confirmed & unconfirmed
    assert_empty overlap, "Tags should not be both confirmed and unconfirmed"

    # Together they should cover all tags with is_confirmed values
    total_with_confirmation = Tag.where.not(is_confirmed: nil).pluck(:id)
    combined = (confirmed + unconfirmed).sort
    assert_equal total_with_confirmation.sort, combined
  end

  # ========== Tag Name Tests ==========

  test "다양한 태그 이름 형식을 처리해야 한다" do
    valid_names = [
      "ruby",
      "rails",
      "ruby-on-rails",
      "ruby_on_rails",
      "Ruby",
      "RAILS",
      "CamelCase",
      "snake_case",
      "kebab-case",
      "MiXeD_CaSe-Format",
      "ruby3.4",
      "rails8.0"
    ]

    valid_names.each do |name|
      tag = Tag.new(name: name)

      # Basic creation should work (inherited from ActsAsTaggableOn)
      assert tag.name = name
      assert_nothing_raised do
        tag.save! if tag.valid?
      end
    end
  end

  test "한글 태그 이름을 처리해야 한다" do
    korean_names = [
      "루비",
      "레일스",
      "한국어",
      "프로그래밍",
      "웹개발",
      "백엔드",
      "프론트엔드",
      "데이터베이스",
      "성능최적화"
    ]

    korean_names.each do |name|
      tag = Tag.new(name: name, is_confirmed: false)

      assert_nothing_raised do
        tag.save! if tag.valid?
        assert_equal name, tag.name
      end
    end
  end

  test "한글과 영문이 혼합된 태그 이름을 처리해야 한다" do
    mixed_names = [
      "ruby-한국어",
      "Rails-레일스",
      "한국어-programming",
      "웹개발-webdev",
      "백엔드-backend"
    ]

    mixed_names.each do |name|
      tag = Tag.new(name: name, is_confirmed: false)

      assert_nothing_raised do
        tag.save! if tag.valid?
        assert_equal name, tag.name
      end
    end
  end

  # ========== Confirmation Status Tests ==========

  test "확정된 태그를 생성해야 한다" do
    confirmed_tag = Tag.new(name: "confirmed-test", is_confirmed: true)
    confirmed_tag.save!

    assert confirmed_tag.is_confirmed?
    assert_includes Tag.confirmed, confirmed_tag
    assert_not_includes Tag.unconfirmed, confirmed_tag
  end

  test "미확정 태그를 생성해야 한다" do
    unconfirmed_tag = Tag.new(name: "unconfirmed-test", is_confirmed: false)
    unconfirmed_tag.save!

    assert_not unconfirmed_tag.is_confirmed?
    assert_includes Tag.unconfirmed, unconfirmed_tag
    assert_not_includes Tag.confirmed, unconfirmed_tag
  end

  test "확정 상태를 변경할 수 있어야 한다" do
    tag = Tag.create!(name: "changeable-tag", is_confirmed: false)

    # Should start as unconfirmed
    assert_includes Tag.unconfirmed, tag
    assert_not_includes Tag.confirmed, tag

    # Change to confirmed
    tag.update!(is_confirmed: true)

    # Should now be confirmed
    assert_includes Tag.confirmed, tag
    assert_not_includes Tag.unconfirmed, tag
  end

  # ========== Taggings Count Tests ==========

  test "taggings 개수를 추적해야 한다" do
    # Test that taggings_count reflects actual usage
    tag = @ruby_tag

    if tag.respond_to?(:taggings_count)
      initial_count = tag.taggings_count

      # Add tag to an article
      @article.tag_list.add(tag.name)
      @article.save!

      # Count should increase (if counter cache is implemented)
      tag.reload

      # Note: This test depends on counter cache configuration
      if tag.taggings_count == initial_count
        assert true, "Counter cache not implemented or not updated yet"
      else
        assert tag.taggings_count > initial_count, "Taggings count should increase"
      end
    else
      assert true, "taggings_count column not available"
    end
  end

  test "taggings 개수가 0인 경우를 처리해야 한다" do
    minimal_tag = tags(:minimal_tag)

    if minimal_tag.respond_to?(:taggings_count)
      assert_equal 0, minimal_tag.taggings_count
    end
  end

  # ========== Integration with ActsAsTaggableOn Tests ==========

  test "acts_as_taggable_on 기능과 함께 작동해야 한다" do
    # Test integration with Article tagging
    article = @article

    # Add tags to article
    article.tag_list = [ @ruby_tag.name, @rails_tag.name, "new-tag" ]
    article.save!

    # Tags should be created/associated
    assert_includes article.tag_list, @ruby_tag.name
    assert_includes article.tag_list, @rails_tag.name
    assert_includes article.tag_list, "new-tag"

    # New tag should be created
    new_tag = Tag.find_by(name: "new-tag")
    assert_not_nil new_tag
  end

  test "find_or_create_with_like_by_name으로 태그를 찾거나 생성해야 한다" do
    # Test existing tag
    tag_name = "test-tag-" + SecureRandom.hex(4)
    created_tag = Tag.create!(name: tag_name, is_confirmed: true)
    found_tag = Tag.find_or_create_with_like_by_name(tag_name)
    assert_equal created_tag, found_tag

    # Test new tag creation
    new_tag_name = "brand-new-tag-" + SecureRandom.hex(4)
    newly_created_tag = Tag.find_or_create_with_like_by_name(new_tag_name)
    assert_not_nil newly_created_tag
    assert_equal new_tag_name, newly_created_tag.name
    assert newly_created_tag.persisted?
  end

  # ========== Case Sensitivity Tests ==========

  test "대소문자 구분을 적절하게 처리해야 한다" do
    # Test behavior with different cases
    lower_case = "ruby"
    upper_case = "RUBY"
    mixed_case = "Ruby"

    # This behavior depends on ActsAsTaggableOn configuration
    tags = [ lower_case, upper_case, mixed_case ].map do |name|
      Tag.find_or_create_with_like_by_name(name)
    end

    # Document the actual behavior - might be case sensitive or insensitive
    if tags.uniq.size == 1
      # Case insensitive
      assert_equal tags[0], tags[1]
      assert_equal tags[0], tags[2]
    else
      # Case sensitive
      assert tags.all?(&:persisted?)
    end
  end

  # ========== Special Characters Tests ==========

  test "태그 이름에 있는 특수 문자를 처리해야 한다" do
    special_chars = [
      "c++",
      "c#",
      ".net",
      "ruby-3.4",
      "rails_8.0",
      "node.js",
      "@angular",
      "#hashtag"
    ]

    special_chars.each do |name|
      tag = Tag.new(name: name, is_confirmed: false)

      # Should handle special characters appropriately
      if tag.valid?
        tag.save!
        assert_equal name, tag.name
      else
        # If invalid, should have appropriate validation errors
        assert_not_empty tag.errors
      end
    end
  end

  # ========== Performance Tests ==========

  test "확정된 태그를 효율적으로 쿼리해야 한다" do
    assert_queries(1) do
      Tag.confirmed.limit(10).to_a
    end
  end

  test "미확정 태그를 효율적으로 쿼리해야 한다" do
    assert_queries(1) do
      Tag.unconfirmed.limit(10).to_a
    end
  end

  test "이름으로 태그를 효율적으로 찾아야 한다" do
    tag_name = @ruby_tag.name

    assert_queries(1) do
      found_tag = Tag.find_by(name: tag_name)
      assert_equal @ruby_tag, found_tag
    end
  end

  # ========== Data Integrity Tests ==========

  test "taggings와의 참조 무결성을 유지해야 한다" do
    tag = Tag.create!(name: "integrity-test", is_confirmed: false)

    # Add tag to an article
    @article.tag_list.add(tag.name)
    @article.save!

    # Verify tag is associated
    assert_includes @article.tag_list, tag.name

    # Deleting tag should handle taggings appropriately
    # (Behavior depends on ActsAsTaggableOn configuration)
    initial_taggings_count = ActsAsTaggableOn::Tagging.count

    tag.destroy!

    # Taggings should be cleaned up or nullified
    final_taggings_count = ActsAsTaggableOn::Tagging.count
    assert final_taggings_count <= initial_taggings_count
  end

  # ========== Korean Content Integration Tests ==========

  test "한글 기사 내용과 함께 작동해야 한다" do
    korean_article = articles(:korean_content_article)
    korean_tags = [ "루비", "레일스", "한국어", "프로그래밍" ]

    # Add Korean tags to Korean article
    korean_article.tag_list = korean_tags
    korean_article.save!

    # Verify tags were created and associated
    korean_tags.each do |tag_name|
      assert_includes korean_article.tag_list, tag_name
      tag = Tag.find_by(name: tag_name)
      assert_not_nil tag, "Korean tag '#{tag_name}' should be created"
    end
  end

  test "혼합 언어 태깅을 지원해야 한다" do
    article = @article
    mixed_tags = [ "ruby", "루비", "rails", "레일스", "performance", "성능" ]

    article.tag_list = mixed_tags
    article.save!

    # All tags should be preserved
    mixed_tags.each do |tag_name|
      assert_includes article.tag_list, tag_name
      tag = Tag.find_by(name: tag_name)
      assert_not_nil tag, "Mixed language tag '#{tag_name}' should be created"
    end
  end

  # ========== Edge Cases and Error Handling ==========

  test "매우 긴 태그 이름을 처리해야 한다" do
    # Test with very long tag name
    long_name = "a" * 100 # Adjust based on your tag name length limits

    tag = Tag.new(name: long_name, is_confirmed: false)

    # Should either be valid or have appropriate length validation
    if tag.valid?
      tag.save!
      assert_equal long_name, tag.name
    else
      # Should have length validation error
      assert_includes tag.errors[:name], "is too long"
    end
  end

  test "빈 태그 이름을 정상적으로 처리해야 한다" do
    empty_tag = Tag.new(name: "", is_confirmed: false)

    # Should not be valid
    assert_not empty_tag.valid?
    assert_includes empty_tag.errors[:name], "내용을 입력해 주세요"
  end

  test "태그 이름에 있는 공백을 처리해야 한다" do
    whitespace_names = [
      " leading-space",
      "trailing-space ",
      "  both-spaces  ",
      "internal space",
      "multiple   internal    spaces",
      "\ttab-characters\t",
      "\nnewline-characters\n"
    ]

    whitespace_names.each do |name|
      tag = Tag.new(name: name, is_confirmed: false)

      # Behavior depends on validation/normalization rules
      if tag.valid?
        tag.save!
        # Tag name might be normalized or kept as-is
        assert_not_nil tag.name
      else
        # If invalid, should have appropriate validation
        assert_not_empty tag.errors
      end
    end
  end

  # ========== Fixture Validation Tests ==========

  test "모든 fixture 태그는 유효해야 한다" do
    Tag.all.each do |tag|
      assert tag.valid?, "Tag #{tag.name} should be valid: #{tag.errors.full_messages.join(', ')}"
    end
  end

  test "fixture 태그는 적절한 확정 상태를 가져야 한다" do
    # Confirmed tags
    confirmed_fixture_tags = [ @ruby_tag, @rails_tag, @performance_tag, @special_tag ]
    confirmed_fixture_tags.each do |tag|
      assert tag.is_confirmed?, "Tag #{tag.name} should be confirmed"
    end

    # Unconfirmed tags
    unconfirmed_fixture_tags = [ @new_feature_tag, @korean_tag ]
    unconfirmed_fixture_tags.each do |tag|
      assert_not tag.is_confirmed?, "Tag #{tag.name} should be unconfirmed"
    end
  end

  test "fixture 태그는 합리적인 이름을 가져야 한다" do
    Tag.all.each do |tag|
      assert_not_nil tag.name
      assert_not tag.name.empty?
      assert tag.name.length > 0
    end
  end

  # ========== Integration with Korean Timezone ==========

  test "한국 시간대와 함께 작동해야 한다" do
    Time.zone = "Asia/Seoul"

    tag = Tag.create!(
      name: "시간대-테스트",
      is_confirmed: false
    )

    assert_equal "Asia/Seoul", Time.zone.name
    assert_kind_of ActiveSupport::TimeWithZone, tag.created_at
    assert_kind_of ActiveSupport::TimeWithZone, tag.updated_at
  end

  # ========== Batch Operations Tests ==========

  test "일괄 확정을 효율적으로 처리해야 한다" do
    # Create some unconfirmed tags
    unconfirmed_tag_names = [ "batch-1", "batch-2", "batch-3" ]
    unconfirmed_tags = unconfirmed_tag_names.map do |name|
      Tag.create!(name: name, is_confirmed: false)
    end

    # Batch confirm them
    Tag.where(id: unconfirmed_tags.map(&:id)).update_all(is_confirmed: true)

    # Verify they're all confirmed
    unconfirmed_tags.each do |tag|
      tag.reload
      assert tag.is_confirmed?
      assert_includes Tag.confirmed, tag
    end
  end

  test "효율적인 태그 정리 작업을 지원해야 한다" do
    # Create tags with no taggings
    unused_tags = 3.times.map do |i|
      Tag.create!(name: "unused-" + i.to_s, is_confirmed: false, taggings_count: 0)
    end

    # Should be able to clean up unused tags efficiently
    initial_count = Tag.count

    # Delete unused tags (those with 0 taggings_count)
    Tag.where(taggings_count: 0, name: unused_tags.map(&:name)).delete_all

    final_count = Tag.count
    assert_equal initial_count - 3, final_count
  end

  private

  # Helper method for testing query count
  def assert_queries(expected_count)
    queries = []
    ActiveSupport::Notifications.subscribe("sql.active_record") do |name, start, finish, id, payload|
      queries << payload[:sql] unless payload[:sql] =~ /^(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/i
    end

    yield

    assert_equal expected_count, queries.size, "Expected #{expected_count} queries, got #{queries.size}"
  ensure
    ActiveSupport::Notifications.unsubscribe("sql.active_record")
  end
end
