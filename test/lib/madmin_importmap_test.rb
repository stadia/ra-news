# frozen_string_literal: true

require "test_helper"

# madmin이 메인 앱과 동일하게 lexxy.min.js(604KB)를 로드하고, 미사용 trix를
# preload하지 않도록 config/initializers/madmin.rb에서 재정의했는지 고정.
# madmin gem 기본값은 비압축 lexxy.js(917KB) + trix preload true라 비효율적이다.
class MadminImportmapTest < ActiveSupport::TestCase
  def packages
    Madmin.importmap.instance_variable_get(:@packages)
  end

  test "madmin importmap은 lexxy를 lexxy.min.js로 pin한다(비압축 lexxy.js 아님)" do
    lexxy = packages["lexxy"]

    assert lexxy, "lexxy pin이 존재해야 한다"
    assert_equal "lexxy.min.js", lexxy.path
    assert lexxy.preload, "lexxy는 에디터 로드를 위해 여전히 preload되어야 한다"
  end

  test "madmin importmap은 미사용 trix를 preload하지 않는다" do
    trix = packages["trix"]
    # trix는 gem이 defined?(::Trix)일 때만 pin. 존재하면 preload가 꺼져 있어야 한다.
    return unless trix

    refute trix.preload, "trix는 미사용이므로 modulepreload하면 안 된다"
  end
end
