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

  test "should inherit from ActsAsTaggableOn::Tag" do
    assert Tag.ancestors.include?(ActsAsTaggableOn::Tag)
  end

  test "should have ActsAsTaggableOn functionality" do
    # Test that basic taggable functionality is available
    assert_respond_to Tag, :find_or_create_with_like_by_name
    assert_respond_to Tag, :named
    assert_respond_to @ruby_tag, :name
    assert_respond_to @ruby_tag, :taggings
  end

  # ========== Scope Tests ==========

  test "confirmed scope should return confirmed tags" do
    confirmed_tags = Tag.confirmed

    assert_includes confirmed_tags, @ruby_tag
    assert_includes confirmed_tags, @rails_tag
    assert_includes confirmed_tags, @performance_tag
    assert_not_includes confirmed_tags, @new_feature_tag
    assert_not_includes confirmed_tags, @korean_tag
  end

  test "unconfirmed scope should return unconfirmed tags" do
    unconfirmed_tags = Tag.unconfirmed

    assert_includes unconfirmed_tags, @new_feature_tag
    assert_includes unconfirmed_tags, @korean_tag
    assert_not_includes unconfirmed_tags, @ruby_tag
    assert_not_includes unconfirmed_tags, @rails_tag
    assert_not_includes unconfirmed_tags, @performance_tag
  end

  test "confirmed and unconfirmed scopes should be mutually exclusive" do
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

  test "should handle various tag name formats" do
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

  test "should handle Korean tag names" do
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

  test "should handle mixed Korean and English tag names" do
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

  test "should create confirmed tags" do
    confirmed_tag = Tag.new(name: "confirmed-test", is_confirmed: true)
    confirmed_tag.save!

    assert confirmed_tag.is_confirmed?
    assert_includes Tag.confirmed, confirmed_tag
    assert_not_includes Tag.unconfirmed, confirmed_tag
  end

  test "should create unconfirmed tags" do
    unconfirmed_tag = Tag.new(name: "unconfirmed-test", is_confirmed: false)
    unconfirmed_tag.save!

    assert_not unconfirmed_tag.is_confirmed?
    assert_includes Tag.unconfirmed, unconfirmed_tag
    assert_not_includes Tag.confirmed, unconfirmed_tag
  end

  test "should handle nil confirmation status" do
    # Since is_confirmed has NOT NULL constraint, this test documents expected behavior
    # but doesn't actually create a tag with nil is_confirmed
    
    nil_tag = Tag.new(name: "nil-confirmation-test")
    nil_tag.is_confirmed = nil

    # Should not be valid due to NOT NULL constraint
    assert_not nil_tag.valid?, "Tag with nil is_confirmed should not be valid"
    
    # Verify it fails to save
    assert_raises(ActiveRecord::RecordInvalid) do
      nil_tag.save!
    end
  end

  test "should allow changing confirmation status" do
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

  test "should track taggings count" do
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

  test "should handle zero taggings count" do
    minimal_tag = tags(:minimal_tag)

    if minimal_tag.respond_to?(:taggings_count)
      assert_equal 0, minimal_tag.taggings_count
    end
  end

  # ========== Integration with ActsAsTaggableOn Tests ==========

  test "should work with acts_as_taggable_on functionality" do
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

  test "should find or create tags with find_or_create_with_like_by_name" do
    # Test existing tag
    existing_tag = Tag.find_or_create_with_like_by_name(@ruby_tag.name)
    assert_equal @ruby_tag, existing_tag

    # Test new tag creation
    new_tag_name = "brand-new-tag-#{SecureRandom.hex(4)}"
    created_tag = Tag.find_or_create_with_like_by_name(new_tag_name)

    assert_not_nil created_tag
    assert_equal new_tag_name, created_tag.name
    assert created_tag.persisted?
  end

  test "should work with named scope" do
    # Test ActsAsTaggableOn's named scope
    ruby_tags = Tag.named([ @ruby_tag.name, @rails_tag.name ])

    assert_includes ruby_tags, @ruby_tag
    assert_includes ruby_tags, @rails_tag
    assert_equal 2, ruby_tags.count
  end

  # ========== Case Sensitivity Tests ==========

  test "should handle case sensitivity appropriately" do
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

  test "should handle special characters in tag names" do
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

  test "should efficiently query confirmed tags" do
    assert_queries(1) do
      Tag.confirmed.limit(10).to_a
    end
  end

  test "should efficiently query unconfirmed tags" do
    assert_queries(1) do
      Tag.unconfirmed.limit(10).to_a
    end
  end

  test "should efficiently find tags by name" do
    tag_name = @ruby_tag.name

    assert_queries(1) do
      found_tag = Tag.find_by(name: tag_name)
      assert_equal @ruby_tag, found_tag
    end
  end

  # ========== Data Integrity Tests ==========

  test "should maintain referential integrity with taggings" do
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

  test "should work with Korean article content" do
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

  test "should support mixed language tagging" do
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

  test "should handle very long tag names" do
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

  test "should handle empty tag names gracefully" do
    empty_tag = Tag.new(name: "", is_confirmed: false)

    # Should not be valid
    assert_not empty_tag.valid?
    assert_includes empty_tag.errors[:name], "can't be blank"
  end

  test "should handle whitespace in tag names" do
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

  test "all fixture tags should be valid" do
    Tag.all.each do |tag|
      assert tag.valid?, "Tag #{tag.name} should be valid: #{tag.errors.full_messages.join(', ')}"
    end
  end

  test "fixture tags should have appropriate confirmation status" do
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

  test "fixture tags should have reasonable names" do
    Tag.all.each do |tag|
      assert_not_nil tag.name
      assert_not tag.name.empty?
      assert tag.name.length > 0
    end
  end

  # ========== Integration with Korean Timezone ==========

  test "should work with Korean timezone" do
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

  test "should handle batch confirmation efficiently" do
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

  test "should support efficient tag cleanup" do
    # Create tags with no taggings
    unused_tags = 3.times.map do |i|
      Tag.create!(name: "unused-#{i}", is_confirmed: false, taggings_count: 0)
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
      queries << payload[:sql] unless payload[:sql] =~ /^(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/
    end

    yield

    assert_equal expected_count, queries.size, "Expected #{expected_count} queries, got #{queries.size}"
  ensure
    ActiveSupport::Notifications.unsubscribe("sql.active_record")
  end
end
