# 프롬프트 엔지니어링 분석 — Anthropic 기법

> Anthropic 내부 코드베이스(Ant-only) 및 공개 제품에서 사용하는 프롬프트 패턴 분석

---

## 1. 강조 및 주의 제어 (Emphasis & Attention Control)

### 1.1 대문자로 행동 잠금 (CAPS for Behavioral Locks)

**예시:** `BashTool/prompt.ts` — "NEVER" 12회 이상 사용
- "NEVER update the git config"
- "NEVER run destructive git commands"
- "NEVER skip hooks (--no-verify)"

**왜 효과적인가:** 대문자는 시각적/의미적 가중치를 모두 높임. 모델은 대문자 금지사항을 일반 텍스트보다 우선순위 높은 제약으로 처리함.

### 1.2 IMPORTANT/CRITICAL 접두사

**예시:** `compact/prompt.ts`
```text
"CRITICAL: Respond with TEXT ONLY. Do NOT call any tools."
```

**왜 효과적인가:** "CRITICAL"은 프롬프트 시작 부분에서 사용되어 첫 읽기 주의를 잡음. 실패 결과("you will fail the task")와 결합하면 제약이 강화됨.

### 1.3 삼중 반복 패턴 (Triple-Redundancy Pattern)

**예시:** `compact/prompt.ts` — 도구 금지가 3곳에 등장
1. **Preamble:** "CRITICAL: Respond with TEXT ONLY"
2. **Body:** 지시사항 내
3. **Trailer:** "REMINDER: Do NOT call any tools"

**왜 효과적인가:** Recency bias(최근성 편향)를 활용. 트레일러는 컨텍스트에서 가장 최근이고, 프리앰블은 첫 읽기 주의를 담당. 세 번 반복은 단일 강한 문장보다 효과적.

---

## 2. 구조적 패턴 (Structural Patterns)

### 2.1 계층적 섹션 헤더

**예시:** `prompts.ts`
```text
# System
# Doing tasks
# Using your tools
# Executing actions with care
# Tone and style
# Output efficiency
```

**왜 효과적인가:** 명확한 섹션 헤더가 인지적 버킷을 만들어, 모델이 서로 다른 지시 영역을 독립적으로 참조하고 우선순위를 정할 수 있음.

### 2.2 XML 태그 스크래치패드 → 제거 패턴

**예시:** `compact/prompt.ts`
```text
"wrap your analysis in <analysis> tags"
// 이후 코드에서:
formattedSummary.replace(/<analysis>[\s\S]*?<\/analysis>/, '')
```

**왜 효과적인가:** `<analysis>` 태그는 이중 목적으로 사용됨 — 생성 시 추론 품질을 높이지만, 최종 출력에서는 제거됨. 강제 추론이 품질을 개선하되, 추론 자체는 사용자에게 노출되지 않는 기법.

> 💡 **Insight:** 이것은 "chain-of-thought stripping" 패턴으로, Anthropic이 자사 제품에서 사용하는 핵심 기법입니다. 모델에게 XML 태그 안에서 사고하도록 강제한 뒤 post-processing으로 제거하면, 추론 품질은 유지하면서 출력은 깔끔하게 됩니다.

### 2.3 캐시 경계 마커

**예시:** `prompts.ts`
```typescript
export const SYSTEM_PROMPT_DYNAMIC_BOUNDARY = '__SYSTEM_PROMPT_DYNAMIC_BOUNDARY__'
```

**왜 효과적인가:** 메타-프롬프팅 — 프롬프트 자체가 자신의 처리 방법을 포함함. 정적(전역 캐시 가능) 콘텐츠와 동적(세션별) 콘텐츠를 분리하여 API 비용 최적화.

### 2.4 구조화된 환경 컨텍스트

**예시:** `prompts.ts`
```xml
<env>
Working directory: ${getCwd()}
Platform: ${env.platform}
Shell: ${shellName}
</env>
```

**왜 효과적인가:** XML 태그가 구조화된 데이터임을 신호함. 모델이 환경 정보를 쿼리 가능한 사실로 처리.

---

## 3. 행동 제어 (Behavioral Control)

### 3.1 When/When NOT 분기

**예시:** `EnterPlanModeTool/prompt.ts`
```text
"### GOOD - Use EnterPlanMode:" (7 예시)
"### BAD - Don't use EnterPlanMode:" (4 예시)
```

**왜 효과적인가:** 긍정/부정 사례를 명시적으로 분리하여, 모델이 도구를 범용 대안으로 사용하는 것을 방지.

### 3.2 구체적 휴리스틱으로 과도한 추상화 방지

**예시:** `prompts.ts`
```text
"Three similar lines of code is better than a premature abstraction."
```

**왜 효과적인가:** 모호한 "과도하게 하지 마라" 대신 구체적 비율을 제공. 3줄 vs 추상화라는 의사결정 기준이 됨.

### 3.3 필수 검증 게이트

**예시:** `prompts.ts` (ant-only)
```text
"Before reporting a task complete, verify it actually works: run the test,
execute the script, check the output. If you can't verify, say so explicitly
rather than claiming success."
```

**왜 효과적인가:** 완료 선언 전 명시적 게이트를 만듦. "say so explicitly"는 검증 불가 시에도 침묵이 아닌 명시적 보고를 강제.

### 3.4 정직한 보고 명령

**예시:** `prompts.ts` (ant-only)
```text
"Never claim 'all tests pass' when output shows failures, never suppress or
simplify failing checks to manufacture a green result, and never characterize
incomplete work as done."
```

**왜 효과적인가:** 삼중 부정("never...never...never")으로 결과 미화를 원천 차단. 가짜 성공 보고라는 특정 실패 모드를 이름으로 지목.

### 3.5 위험 기반 권한 프레임워크

**예시:** `prompts.ts`
```text
"Carefully consider the reversibility and blast radius of actions."
```

**왜 효과적인가:** 단순 이진 규칙 대신 원칙적 프레임워크(가역성 + 영향 범위)를 제공하여, 새로운 상황에서도 모델이 적용 가능.

---

## 4. 환각 방지 (Anti-Hallucination)

### 4.1 선결조건 체인

**예시:** `FileEditTool/prompt.ts`
```text
"You must use your Read tool at least once before editing.
This tool will error if you attempt an edit without reading the file."
```

**왜 효과적인가:** "will error"라는 보장된 실패를 선언함으로써, 모델이 지름길을 시도하는 것을 방지.

### 4.2 형식 나열과 함께 창작 금지

**예시:** `AgentTool/prompt.ts` (fork mode)
```text
"Never fabricate or predict fork results in any format — not as prose,
summary, or structured output."
```

**왜 효과적인가:** 나쁜 행동뿐 아니라 그것이 나타날 형태(산문, 요약, 구조화된 출력)까지 명시. 대안("give status, not a guess")도 제공.

### 4.3 스냅샷 의미론 면책

**예시:** `context.ts`
```text
"This is the git status at the start of the conversation. Note that this
status is a snapshot in time, and will not update during the conversation."
```

**왜 효과적인가:** 시간에 민감한 정보가 오래될 수 있음을 명시하여, 모델이 현실과 달라진 상태에 의존하는 것을 방지.

### 4.4 지식 컷오프 선언

**예시:** `prompts.ts`
```text
"Assistant knowledge cutoff is ${cutoff}."
```

**왜 효과적인가:** 모델별 다른 cutoff 날짜(Sonnet: 2025/8, Opus: 2025/5)를 설정하여 훈련 데이터 이후 사건에 대한 환각 방지.

---

## 5. 도구 선택 가이드 (Tool Selection Guidance)

### 5.1 명시적 선호 계층 + 부정

**예시:** `BashTool/prompt.ts`
```text
"File search: Use Glob (NOT find or ls)
Content search: Use Grep (NOT grep or rg)
Read files: Use Read (NOT cat/head/tail)
Edit files: Use Edit (NOT sed/awk)"
```

**왜 효과적인가:** 선호 도구와 금지 도구를 동시에 나열. 모델은 "해야 할 것"과 "하지 말아야 할 것"을 한 줄에서 학습.

### 5.2 검색 vs 조회 구분

**예시:** `AgentTool/prompt.ts`
```text
"For simple, directed codebase searches → use Glob or Grep directly.
For broader codebase exploration → use Agent with subagent_type=Explore."
```

**왜 효과적인가:** 작업의 성격(특정 검색 vs 탐색)에 따라 도구를 구분, 과도한 도구 사용(Agent로 알려진 파일 읽기)과 부족한 도구 사용(Grep으로 열린 탐색)을 모두 방지.

### 5.3 역량 기반 에이전트 할당

**예시:** `TeamCreateTool/prompt.ts`
```text
"Read-only agents (e.g., Explore, Plan) cannot edit or write files.
Only assign them research, search, or planning tasks."
```

**왜 효과적인가:** 에이전트 능력과 작업 요구사항을 사전에 매칭하여, 능력이 없는 에이전트에 작업 할당을 방지.

---

## 6. 다중 에이전트 조율 (Multi-Agent Coordination)

### 6.1 가시성 경계 선언

**예시:** `SendMessageTool/prompt.ts`
```text
"Your plain text output is NOT visible to other agents — to communicate,
you MUST call this tool."
```

**왜 효과적인가:** 공유 상태나 가시성에 대한 가정을 명시적으로 차단. "말했다"와 "실제로 전달됐다"의 구분을 강제.

### 6.2 유휴 상태 정상화

**예시:** `TeamCreateTool/prompt.ts`
```text
"Teammates go idle after every turn—this is completely normal and expected.
Do not treat idle as an error."
```

**왜 효과적인가:** 에이전트 비활성을 실패로 해석하는 것을 방지. "정상"으로 재프레이밍하여 불필요한 "수정" 시도 차단.

### 6.3 Fork vs Subagent 의미론

| 유형 | 특성 | 프롬프트 역할 |
|------|------|-------------|
| **Fork** | "inherits your full conversation context" | 지시(directive) |
| **Subagent** | "starts fresh" | 브리핑(briefing) |

**왜 효과적인가:** 두 경로의 의미론을 명확히 하여, 각각에 맞는 프롬프트 작성 방식을 교육.

### 6.4 엿보지 않기 (컨텍스트 오염 방지)

**예시:** `AgentTool/prompt.ts`
```text
"Do not Read or tail the output_file unless the user explicitly asks.
Reading the transcript mid-flight pulls the fork's tool noise into your
context, which defeats the point of forking."
```

**왜 효과적인가:** 특정 실패 모드(컨텍스트 오염)를 이름으로 지목하고 그 이유를 설명. "defeats the point"라는 표현이 행동의 결과를 명확히 함.

---

## 7. 구체적 제약 (Concrete Constraints)

### 7.1 숫자 기반 길이 앵커

**예시:** `prompts.ts` (ant-only)
```text
"Length limits: keep text between tool calls to ≤25 words.
Keep final responses to ≤100 words unless the task requires more detail."
```

**왜 효과적인가:** 모호한 "간결하게"를 측정 가능한 숫자로 대체. 연구에 따르면 정성적 지시 대비 ~1.2% 출력 토큰 감소.

### 7.2 토큰 예산을 작업 변수로

**예시:** `prompts.ts`
```text
"The target is a hard minimum, not a suggestion. If you stop early,
the system will automatically continue you."
```

**왜 효과적인가:** 토큰 예산을 효율성 제약이 아닌 채워야 할 목표로 재프레이밍. "하드 미니멈"이라는 표현이 무시를 방지.

### 7.3 인덱스 파일 문자 제한

**예시:** `memdir.ts`
```text
"each entry should be one line, under ~150 characters"
"lines after 200 will be truncated, so keep the index concise"
```

**왜 효과적인가:** 잘림(truncation)이라는 구체적 결과를 통해 간결함을 강제. 측정 가능한 제약이 모호한 "be concise"보다 강력.

---

## 8. 역할 및 정체성 (Role & Identity)

### 8.1 협력자 vs 실행자 프레이밍

**예시:** `prompts.ts` (ant-only)
```text
"You're a collaborator, not just an executor—users benefit from your
judgment, not just your compliance."
```

**왜 효과적인가:** 대시로 구분된 대조("not just an executor")가 역할을 재프레이밍. 모델의 기능 인식을 단순 작업 수행에서 협업 판단으로 전환.

### 8.2 읽기 전용 에이전트 정체성

**예시:** `exploreAgent.ts`
```text
"=== CRITICAL: READ-ONLY MODE - NO FILE MODIFICATIONS ===
You are STRICTLY PROHIBITED from:
- Creating new files
- Modifying existing files
- Deleting files..."
```

**왜 효과적인가:** 허용 목록(whitelist) 대신 금지 목록 열거를 사용. 창의적 우회("/tmp에 임시 파일" 등)까지 명시적으로 차단.

### 8.3 동반자 비간섭

**예시:** `buddy/prompt.ts`
```text
"Your job is to stay out of the way: respond in ONE line or less.
Don't explain that you're not ${name} — they know."
```

**왜 효과적인가:** 공유 UI에서 역할 분리를 교육. "they know"라는 가정이 불필요한 메타 설명을 방지.

---

## 9. 조건부 적응 프롬프팅 (Conditional & Adaptive Prompting)

### 9.1 사용자 유형 분기

**예시:** `prompts.ts`, `EnterPlanModeTool/prompt.ts`
```typescript
process.env.USER_TYPE === 'ant'
? [stricter rules, false-claims mitigation, numeric anchors]
: [simpler, more concise instructions]
```

**왜 효과적인가:** 동일 코드베이스에서 다른 행동 프로파일을 제공. 내부 사용자에게 공격적 최적화를 먼저 테스트한 후 외부에 배포하는 A/B 테스트 파이프라인.

### 9.2 터미널 포커스 적응

**예시:** `prompts.ts` (proactive mode)
```text
"- **Unfocused**: The user is away. Lean heavily into autonomous action
- **Focused**: The user is watching. Be more collaborative"
```

**왜 효과적인가:** 사용자 주의 상태에 따라 자율성 수준을 실시간 조정하는 피드백 루프.

### 9.3 기능 플래그 게이팅 섹션

**예시:** `prompts.ts`
```typescript
const SleepTool = feature('PROACTIVE') || feature('KAIROS')
? require('./tools/SleepTool/SleepTool.js').SleepTool : null
```

**왜 효과적인가:** Bun의 dead code elimination을 활용한 컴파일타임 프롬프트 최적화. 불필요한 섹션이 빌드에서 완전히 제거됨.

### 9.4 동적 경고 생성

**예시:** `SessionMemory/prompts.ts`
```typescript
if (oversizedSections.length > 0) {
parts.push(`IMPORTANT: The following sections exceed the per-section limit
and MUST be condensed:\n${oversizedSections.join('\n')}`)
}
```

**왜 효과적인가:** 정적 지시가 아닌, 실제 상태 기반의 동적 경고를 생성. "이전 출력이 너무 깁니다"라는 구체적 피드백이 추상적 규칙보다 강력.

---

## 10. 효율성 및 메타인지 (Efficiency & Meta-Cognition)

### 10.1 턴 예산 전략 교육

**예시:** `extractMemories/prompts.ts`
```text
"turn 1 — issue all Read calls in parallel for every file you might update;
turn 2 — issue all Write/Edit calls in parallel.
Do not interleave reads and writes across multiple turns."
```

**왜 효과적인가:** 시행착오가 아닌 최적 실행 전략을 직접 교육. 제한된 턴 예산을 가진 백그라운드 에이전트에 필수적.

### 10.2 속도 우선 에이전트 지시

**예시:** `exploreAgent.ts`
```text
"You are meant to be a fast agent that returns output as quickly as possible.
Wherever possible spawn multiple parallel tool calls."
```

**왜 효과적인가:** 최적화 목표를 명시(속도 > 철저함). 모델에게 병렬화 허가와 격려를 동시에 제공.

### 10.3 토큰 절약을 위한 강제 대기

**예시:** `prompts.ts` (proactive mode)
```text
"If you have nothing useful to do on a tick, you MUST call Sleep.
Never respond with only a status message like 'still waiting' —
that wastes a turn and burns tokens for no reason."
```

**왜 효과적인가:** 유휴 상태 서술("아직 기다리는 중")이라는 토큰 낭비를 명시적으로 금지하고 대안(Sleep 도구)을 강제.

### 10.4 대조적 가이드 쌍

**예시:** `MagicDocs/prompts.ts`
```text
"What TO document:
- Non-obvious patterns, conventions, or gotchas
What NOT to document:
- Anything obvious from reading the code itself"
```

**왜 효과적인가:** 좋은 출력의 공간이 나쁜 출력의 공간보다 크므로, 제외 규칙이 포함 규칙보다 효율적. "코드에서 명백한 것"이 탈락 기준이 됨.

### 10.5 안전한 변수 주입

**예시:** `MagicDocs/prompts.ts`
```typescript
// Single-pass replacement avoids: (1) $ backreference corruption
// (2) double-substitution when user content contains {{varName}}
template.replace(/\{\{(\w+)\}\}/g, (match, key) => variables[key] ?? match)
```

**왜 효과적인가:** 사용자 콘텐츠에 변수명이 포함된 경우의 프롬프트 인젝션 방지. 단일 패스로 이중 치환과 $ 참조 오류를 동시에 방지.

---

## 핵심 인사이트 (Key Insights)

### 가장 핵심적인 3가지 발견:

| 순위 | 패턴 | 설명 |
|------|------|------|
| 1 | **Chain-of-thought stripping** | `<analysis>` 태그로 추론 강제 후 제거 → 품질과 깔끔함을 동시 달성 |
| 2 | **삼중 반복 패턴** | 중요한 제약을 프리앰블/본문/트레일러에 3회 배치하여 recency bias 활용 |
| 3 | **구체적 숫자** | `≤25 words`, `~150 chars`, `200 line limit` — 정성적 "간결하게"보다 측정 가능한 제약이 ~1.2% 더 효과적 |

> **참고:** 이 기법들은 Anthropic이 자체 제품에서 프롬프트 엔지니어링을 어떻게 하는지 보여주는 일급 자료입니다. 특히 "내부(ant) vs 외부" 이중 트랙은 프롬프트 최적화의 A/B 테스트 파이프라인 그 자체입니다.