#!/usr/bin/env ruby
# frozen_string_literal: true

# tapioca 가 생성한 gem RBI 의 알려진 결함을 보정한다.
#
# `bundle exec tapioca gem <name>` 직후에 실행한다.
#
#     bundle exec tapioca gem fedipub && ruby script/patch_generated_gem_rbis.rb
#
# 왜 젬이 아니라 여기서 고치는가:
#   Ruby 3.2+ 의 익명 파라미터 포워딩(`def m(*)`, `(**, &)`)은 정상적인 관용구다.
#   tapioca 가 `Method#parameters` 에서 이름을 얻지 못해 타입이 빈 sig
#   (`params(_arg1: , _arg2: )`) 를 뱉는 것은 tapioca 의 한계이지 젬의 결함이
#   아니다. 도구의 한계는 그 도구를 쓰는 쪽에서 흡수한다 - 라이브러리 소스를
#   관용구 이전으로 되돌리지 않는다.
#
# upstream PR: Shopify/tapioca#2687 "Preserve anonymous parameters in generated RBIs"
#   Ruby 는 익명 파라미터를 `[[:rest, :*], [:keyrest, :**], [:block, :&]]` 로
#   리플렉션하는데 tapioca 가 그 의사 이름을 유효하지 않다고 보고 `_arg0`/`_arg1`
#   로 바꾼다. Sorbet 은 시그니처 타입을 원래 이름(`"*"`, `"**"`, `"&"`) 아래
#   보관하므로, 이름이 바뀌는 순간 타입 조회가 실패해 타입이 비어 버린다.
#   2026-08-28 기준 APPROVED 상태로 머지 대기 중이다(base 와 충돌해 리베이스 대기).
#   최신 릴리스 v0.19.2(2026-06-25)는 이 PR 보다 앞서므로 아직 수정이 없다.
#
# **#2687 이 머지된 뒤 첫 릴리스(v0.19.3 또는 v0.20.0 이 후보)에서 이 스크립트를
# 통째로 지운다.** 젬을 올릴 때 이 스크립트가 "보정할 항목 없음"을 내면 회수 시점이
# 온 것이다.
# `bundle exec tapioca gem --verify` 는 Gemfile.lock 대비 파일 집합만 검사하므로
# 여기서 내용을 손봐도 CI 는 깨지지 않는다.

require "pathname"

# 빈 타입을 가진 위치 인자를 T.untyped 로 채운다.
#   sig { params(method_name: T.nilable(::Symbol), _arg1: , _arg2: ).returns(...) }
#                                                        ^^^^^^^^^^^^
EMPTY_PARAM_TYPE = /(\b_arg\d+): (?=[,)])/

patched = Pathname.glob("sorbet/rbi/gems/*.rbi").filter_map do |path|
  source = path.read
  fixed, count = source.gsub(EMPTY_PARAM_TYPE) { "#{::Regexp.last_match(1)}: T.untyped" }
                       .then { |s| [ s, source.scan(EMPTY_PARAM_TYPE).size ] }
  next if count.zero?

  path.write(fixed)
  "#{path.basename}: #{count}곳"
end

if patched.empty?
  puts "보정할 항목 없음"
else
  puts "보정 완료"
  patched.each { |line| puts "  #{line}" }
end
