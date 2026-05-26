---
name: ruby-classless-refactor
description: Ruby 클래스를 모듈/함수/Struct/Data로 리팩터링하는 결정 트리와 변환 레시피. "이 클래스 정말 필요한가?", "함수로 바꿔달라", "Struct로 바꿀 수 있나?", "PORO 정리", "app/functions로 옮겨줘" 같은 요청에 사용한다. 새 클래스를 만들기 전에 검증할 때도 사용한다.
---

# Ruby Classless Refactor

> "Ruby는 객체 지향이지 클래스 지향이 아니다. 클래스는 객체 팩토리일 때만 가치가 있다." — Dave Thomas

이 스킬은 기존 Ruby 클래스를 더 단순한 구성요소(모듈 함수 / `Struct` / `Data` / `app/functions/`)로 리팩터링한다. **새 클래스 작성 직전에도 사용 가능**하다 — 동일한 결정 트리로 "이게 정말 클래스여야 하는가"를 판정한다.

## 컨벤션

새 코드를 만들 때, **클래스를 쓰기 전에 아래 체크리스트를 통과해야 한다.** 하나라도 "No"면 클래스가 아닌 다른 도구를 선택한다. (적용 범위: `app/services/`, `app/functions/`, `app/jobs/`, PORO. ActiveRecord/ActionController/ActiveJob/Decorator 등 Rails 프레임워크 클래스는 예외.)

1. **객체 팩토리인가?** — 인스턴스를 여러 개 만들고 각자 상태를 가지는가? 아니면 `Module` (`class << self`) 또는 `app/functions/`로.
2. **상태가 있는가?** — `@ivar`가 생성자에서만 세팅되고 곧바로 단일 메서드를 호출해 끝나는 패턴이면 함수다. `Foo.new(x).call` → `Foo.build(x)`.
3. **디자인 패턴 이름이 붙었는가?** — `XxxFactory`, `XxxBuilder`, `XxxDecorator`(Draper 외)처럼 GoF 패턴명을 그대로 클래스명으로 쓰고 있다면 의심하라. Ruby는 대부분 언어 차원에서 해결한다.
4. **`new` 직후 setter를 추가로 호출해야 유효해지는가?** — 설계 결함. 인자를 함수에 직접 전달하라.
5. **단순 데이터 버킷인가?** — 필드명을 3회 이상 반복(`attr_reader` + `initialize` + 등)하는 PORO는 `Struct`/`Data.define`로 대체. 메서드가 더 필요하면 `Struct.new(...) do ... end`.

근거: Ruby는 객체 지향이지 클래스 지향이 아니다. 클래스가 늘면 결합도가 올라가고 테스트 시 컨텍스트 세팅 비용이 늘어난다. 90%의 경우 클래스 없이 쓰면 메서드가 작아지고 Fat Model이 사라진다.

## 결정 트리 — 어떤 대안으로 갈 것인가

체크리스트의 Q1이 "No"라서 클래스가 아니라고 판정됐을 때, 아래 트리를 위에서 아래로 따라 첫 번째 "Yes"에서 멈춘다.

```
A. Rails 프레임워크 슈퍼클래스를 상속해야 하는가?
   (ApplicationRecord/Controller/Job, Draper::Decorator, ActiveAdmin::ResourceController 등)
   → Yes: 클래스 유지. 로직 본체만 함수로 빼낸다 → 레시피 D.
   → No: 계속.

B. step :validate/persist 같은 모나드 파이프라인(여러 실패 분기 + 트랜잭션)이 필요한가?
   → Yes: OperationService 상속 클래스로.
   → No: 계속.

C. 동작 거의 없이 필드만 담는 데이터 버킷인가?
   (attr_reader/initialize/==에서 필드명을 반복하는 PORO)
   → Yes:
     - 불변이면  → `Data.define(:a, :b)` (레시피 C)
     - 가변이면  → `Struct.new(:a, :b, keyword_init: true)` (레시피 C)
     - 메서드 1~2개 더 필요하면 → `Data.define(...) do ... end`
   → No: 계속.

D. 생성자에서 받은 인자를 단일 메서드 호출에만 쓰는가?
   (Foo.new(x, y).call 패턴, 외부 의존성 없음)
   → Yes: `app/functions/` + `class << self` 순수 함수 → 레시피 A.
   → No: 계속.

E. 여러 private 단계로 쪼개져 있지만 진입점은 하나뿐인가?
   (@lines 같은 누적 변수가 메서드들 사이에서만 공유되는 경우)
   → Yes: `app/functions/` + 인자 명시 전달로 → 레시피 B.
   → No: 체크리스트로 돌아가서 재검토 — 정말 클래스가 맞을 수도 있다.
```

## 변환 레시피

### A. `Foo.new(x).call` → `app/functions/` 모듈 함수

**언제**: 외부 상태/의존성이 없는 순수 변환. 단일 진입점.

Before:
```ruby
# app/services/price_calculator.rb
class PriceCalculator
  def initialize(pick, plan)
    @pick = pick
    @plan = plan
  end

  def call
    base = @pick.kwh * @plan.unit_price
    base + surcharge
  end

  private

  def surcharge
    @pick.peak_hour? ? @pick.kwh * 50 : 0
  end
end

# 호출부
PriceCalculator.new(pick, plan).call
```

After:
```ruby
# app/functions/price_calculator.rb
module PriceCalculator
  extend Loggable  # logger 사용 시 (Rails.logger 직접 호출 금지)

  class << self
    def compute(pick:, plan:)
      base = pick.kwh * plan.unit_price
      base + surcharge(pick)
    end

    private

    def surcharge(pick)
      pick.peak_hour? ? pick.kwh * 50 : 0
    end
  end
end

# 호출부
PriceCalculator.compute(pick: pick, plan: plan)
```

체크:
- 메서드명은 `call` 금지 — `build`/`compute`/`resolve` 같은 도메인 의미가 드러나는 동사 사용
- `private`는 `class << self` 안에서 사용
- 키워드 인자 권장 (호출부 가독성)
- **로깅이 필요하면 `extend Loggable`** — `app/functions/concerns/loggable.rb`가 `delegate :logger, to: :Rails`를 제공. 모듈 내부에서 `Rails.logger.warn`이 아닌 `logger.warn`으로 호출 (기존 `app/functions/` 컨벤션과 일치)

### B. 상태가 있지만 단일 호출만 있는 클래스 → 모듈 함수 + 인자 명시

Before:
```ruby
class ReportBuilder
  def initialize(user, range)
    @user = user
    @range = range
    @lines = []
  end

  def call
    collect_picks
    format_lines
    @lines.join("\n")
  end

  private
  def collect_picks; ... end
  def format_lines; ... end
end
```

After:
```ruby
module ReportBuilder
  extend Loggable

  class << self
    def build(user:, range:)
      picks = collect_picks(user, range)
      format(picks)
    end

    private

    def collect_picks(user, range) = user.picks.where(created_at: range)
    def format(picks) = picks.map { |p| "..." }.join("\n")
  end
end
```

체크: `@lines` 같은 누적 변수는 메서드 반환값으로 바꾼다. 사이드이펙트는 경계로 밀어낸다.

### C. PORO 데이터 버킷 → `Data.define` 또는 `Struct`

**불변** (선호):
```ruby
# Before
class ChargingResult
  attr_reader :pick_id, :kwh, :cost
  def initialize(pick_id:, kwh:, cost:)
    @pick_id = pick_id; @kwh = kwh; @cost = cost
  end
end

# After
ChargingResult = Data.define(:pick_id, :kwh, :cost)
```

**가변이 필요할 때**:
```ruby
ChargingResult = Struct.new(:pick_id, :kwh, :cost, keyword_init: true)
```

**메서드가 한두 개 필요할 때**:
```ruby
ChargingResult = Data.define(:pick_id, :kwh, :cost) do
  def free? = cost.zero?
end
```

### D. 빈 클래스 (`perform`만 있는 Job/Service) → 함수 위임

Job은 Sidekiq 계약상 클래스여야 하지만, 로직 본체는 함수로 분리한다.

Before:
```ruby
class FooJob < ApplicationJob
  def perform(pick_id)
    pick = Pick.find(pick_id)
    pick.update!(status: :done)
    Notifier.send(pick)
    AuditLog.create!(pick: pick)
  end
end
```

After:
```ruby
# app/functions/foo_processor.rb
module FooProcessor
  class << self
    def run(pick)
      pick.update!(status: :done)
      Notifier.send(pick)
      AuditLog.create!(pick: pick)
    end
  end
end

class FooJob < ApplicationJob
  def perform(pick_id) = FooProcessor.run(Pick.find(pick_id))
end
```

테스트 시 Sidekiq 컨텍스트 없이 `FooProcessor`만 단위 테스트 가능 → 컨텍스트 세팅 비용 제거.

## 작업 워크플로우

리팩터링 요청을 받으면 다음 순서로 진행한다.

1. **타깃 식별** — 클래스 파일 경로 확보. 사용자가 명시하지 않았으면 묻는다.
2. **사용처 조사** (필수)
   - `rails 'ai:tool[search_code]' pattern="ClassName" match_type=trace`
   - 모든 호출부를 파악한다. 호출부가 많으면 한 번에 바꾸지 말고 단계적으로.
3. **체크리스트 → 결정 트리 적용** — 먼저 "컨벤션" 섹션의 5개 질문에 답하고 첫 "No"에서 멈춘다. 클래스가 아니라고 판정되면 결정 트리(A~E)를 위에서 아래로 타 첫 "Yes"에서 멈춰 레시피를 확정한다. 두 단계 모두 사용자에게 명시적으로 보여준다.
4. **테스트 우선**
   - 기존 spec이 있으면 그대로 유지하며 호출 형태만 바꾼다.
   - 없으면 변환 전에 spec을 먼저 작성한다 (RED).
5. **변환 적용** — 레시피 그대로.
6. **호출부 일괄 수정** — Step 2에서 모은 모든 호출부.
7. **검증**
   - `rails 'ai:tool[validate]' files=<바뀐 파일들> level=rails`
   - `bundle exec rspec <관련 spec>`
8. **이름 변경 시 주의** — `Foo.new(x).call` → `Foo.build(x)`처럼 호출 형태가 바뀌면 별칭 메서드를 두지 말고 모든 호출부를 한 번에 바꾼다 (절반만 바꾼 상태로 커밋 금지).

## 안티패턴 — 하지 말 것

- **클래스를 모듈로 바꾸기만 하고 동일한 결합도 유지** — `extend self` + 동일한 인스턴스 변수 흉내. 의미가 없다.
- **`Rails.logger`를 모듈 내부에서 직접 호출** — `extend Loggable`로 `logger`만 쓰는 게 컨벤션. `Rails.logger.warn`은 `app/functions/` 외부 경계에서만 사용.
- **순수 함수로 바꾸면서 사이드이펙트를 숨김** — `compute`가 DB를 쓰면 그건 함수가 아니다. 이름이 거짓말을 한다.
- **`Data.define` 안에 비즈니스 로직 잔뜩 넣기** — 데이터 컨테이너의 본분을 넘으면 그건 다시 클래스다.
- **호출부의 절반만 새 API로 마이그레이션** — 일관성 깨진 채 커밋하면 다음 사람이 어느 쪽이 정답인지 모른다.
- **Rails 프레임워크 클래스를 강제로 함수로 변환** — `ApplicationRecord` 모델을 모듈로 만들지 않는다. 결정 트리 1단계에서 멈춰야 한다.

## 사용자에게 보고할 형식

리팩터링 제안 시 항상 아래 형식으로 답한다:

```
대상: app/services/xxx.rb
체크리스트:
  Q1 객체 팩토리? No (호출부 N곳 모두 .new(...).call 1회 호출)
  → 클래스 아님, 결정 트리로
결정 트리:
  A. Rails 슈퍼클래스? No
  B. 모나드 파이프라인? No
  C. 데이터 버킷? No
  D. 단일 메서드 호출에만 인자 사용? Yes → 레시피 A

변환:
  - app/services/xxx.rb → app/functions/xxx.rb
  - 메서드명: call → <동사>
  - 호출부 N곳 수정 필요: <목록>

테스트: spec/services/xxx_spec.rb → spec/functions/xxx_spec.rb (이동 + 호출 형태 수정)
```

사용자 확인 후에만 실제 변경을 시작한다.
