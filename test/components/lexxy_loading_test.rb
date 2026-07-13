# frozen_string_literal: true

require "test_helper"

# lexxy 로딩 레이어가 eager 전역 로딩(최초 설치 방식)을 유지하는지 고정.
# lazy/조건부 로딩(동적 import, preload: false, 페이지별 asset_tags, turbo_permanent
# 밴드에이드)이 재도입되면 빈 화면 회귀가 되돌아오므로 이를 방지한다.
class LexxyLoadingTest < ActiveSupport::TestCase
  APPLICATION_JS = Rails.root.join("app/javascript/application.js").read
  IMPORTMAP = Rails.root.join("config/importmap.rb").read
  LAYOUT = Rails.root.join("app/components/layout.rb").read

  test "application.js는 lexxy를 최상위에서 eager import한다(동적 import 아님)" do
    assert_match(/^import "lexxy";$/, APPLICATION_JS)
    refute_match(/import\("lexxy"\)/, APPLICATION_JS)
  end

  test "importmap은 lexxy를 preload한다(preload: false 아님)" do
    assert_match(/^pin "lexxy", to: "lexxy\.min\.js"$/, IMPORTMAP)
    refute_match(/pin "lexxy".*preload: false/, IMPORTMAP)
  end

  test "layout은 head에서 lexxy CSS를 전역 로드한다" do
    assert_match(/stylesheet_link_tag "lexxy", data_turbo_track: "reload"/, LAYOUT)
    refute_includes LAYOUT, "lexxy CSS는 head에서 전역 로드하지 않는다"
  end

  test "Components::Base는 lexxy_editor_asset_tags를 정의하지 않는다" do
    refute Components::Base.private_method_defined?(:lexxy_editor_asset_tags)
  end
end
