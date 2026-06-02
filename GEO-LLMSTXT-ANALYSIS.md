# llms.txt Analysis: ruby-news.dev

**Analysis Date:** 2026-06-02
**llms.txt Status:** ✅ Found at https://ruby-news.dev/llms.txt (HTTP 200, text/plain, 2,058 bytes, 45 lines)
**llms-full.txt Status:** ❌ Not Found (HTTP 404)
**Source in repo:** `public/llms.txt` (static file)

---

## Overall llms.txt Score: 88/100 (Very Good — top ~5% of the web)

| Dimension | Score | Notes |
|---|---|---|
| Completeness | 80/100 | Covers purpose, scope, AI notes, exclusions. Missing `/about`, topic hubs, llms-full.txt |
| Accuracy | 92/100 | All URLs resolve (200); facts current; descriptions match content |
| Usefulness | 95/100 | Exceptional — explicit "Content Notes for AI Systems" + "Coverage Areas" + "Excluded from AI Indexing" |

**Weighted:** 80×0.40 + 92×0.35 + 95×0.25 = **88/100**

This is a genuinely strong, sophisticated llms.txt — well above the typical file. The improvements below are incremental polish, not fixes for anything broken.

---

## Format Validation

| Element | Status | Notes |
|---|---|---|
| H1 Title | ✅ Pass | `# Ruby-News — 루비 AI 뉴스` |
| Description blockquote | ✅ Pass | Bilingual KO + EN — smart for a translation service. (EN line ~165 chars; KO line concise) |
| H2 Sections | ✅ Pass | 5 sections: About, Key Resources, Content Notes for AI Systems, Coverage Areas, Excluded from AI Indexing |
| Page entries | ✅ Pass | 5 entries in Key Resources, all absolute https URLs |
| URL validity | ✅ Pass | `/`, `/articles`, `/rss`, `/articles?search=` all 200. Mastodon returned 429 (transient rate-limit, profile exists) |
| Entry descriptions | ⚠ Partial | Link text is descriptive, but entries omit the spec's `- [Title](URL): description` trailing description |
| Key Facts | ✅ Pass (effective) | Not titled "Key Facts", but the About bullets provide them (language, topics, article count, cadence, audience) |
| Contact section | ⚠ Missing | No email/contact channel beyond Mastodon. Low severity for a publisher |
| Reasonable length | ✅ Pass | 45 lines (ideal range 30–200) |
| Markdown cleanliness | ✅ Pass | Clean, consistent formatting |

---

## What This File Does Exceptionally Well

1. **"Content Notes for AI Systems"** — explicitly tells AI the content structure (3-bullet 핵심 요약, source URL on every article, RSS author = original source). This is rare and directly improves citation accuracy.
2. **"Coverage Areas"** — precise topical scope (releases, CVEs, RubyGems, performance, RubyKaigi/Rails World, AI/LLM integration) so AI knows exactly when to cite you.
3. **"Excluded from AI Indexing"** — proactively tells AI what to skip (comments, search results, pagination). Sophisticated and consistent with your robots.txt.
4. **Bilingual description** — appropriate for a KO translation service with EN-origin sources.
5. **Provenance transparency** — states content is AI-assisted translation with cited originals, which builds trust with citing models.

---

## Missing Pages (found on site, not in llms.txt)

1. **[소개 / About](https://ruby-news.dev/about)** — Your `NewsMediaOrganization.masthead` already points here. It documents methodology, curation criteria, and the AI-translation disclosure — the single best E-E-A-T/provenance page to surface to AI. **Add this.**
2. **Topic/tag hubs** — e.g. `/tag/rails_8`, `/tag/hotwire`, `/tag/performance_optimization`, `/others`. A few high-value hubs help AI discover category-level depth across 4,000+ articles.
3. **Japanese sibling** — `https://ruby-news.jp` (your `hreflang` alternate). Noting it tells AI a localized JP variant exists.

---

## Improvement Recommendations (priority order)

1. **Add `/about` to Key Resources** with a real description — highest value, one line.
2. **Add explicit `: descriptions`** to each Key Resources entry (spec-compliant, improves disambiguation).
3. **Add a short "Topic Hubs" section** with 4–6 tag/category URLs.
4. **(Optional) Create `llms-full.txt`** — for a 2,487+ article publisher, an extended file listing topic hubs plus 15–30 cornerstone/evergreen articles (e.g. Ruby version releases, Rails upgrade guides) would be a real differentiator and give AI deep, curated entry points.
5. **(Minor) Mention the JP sibling** and optionally bump the article count (sitemap shows ~4,391 URLs; About says "2,400+").
6. **Coordinate with robots.txt** ✅ already aligned — your robots now declares `Content-Signal: ai-input=yes` (citation allowed) and explicitly allows PerplexityBot, which matches this file's intent. Keep them in sync.

---

## Suggested Updated llms.txt

```markdown
# Ruby-News — 루비 AI 뉴스

> Ruby 및 Rails 생태계 뉴스를 AI 보조 번역으로 한국어로 제공하는 기술 뉴스 집약 서비스.
> Korean-language tech news aggregator for the Ruby and Rails ecosystem. 2,500+ articles with AI-assisted Korean translations of English-origin content.

## About

Ruby-News(ruby-news.dev)는 전 세계 Ruby 및 Ruby on Rails 생태계의 뉴스, 릴리즈, 튜토리얼, 커뮤니티 업데이트를 집약하여 AI 보조 한국어 번역과 3개 핵심 요약을 제공합니다. 매일 업데이트됩니다. 일본어판은 ruby-news.jp 에서 제공됩니다.

- 언어: 한국어 (원문 출처: 영어) · 일본어판: https://ruby-news.jp
- 주제: Ruby 언어, Ruby on Rails, RubyGems, Rack, JRuby, Matz 공지, 보안 권고(CVE), 버전 릴리즈, 개발 도구, 성능, AI 연동
- 기사 수: 2,500개 이상
- 업데이트 주기: 매일
- 대상 독자: 한국어권 Ruby·Rails 개발자

## Key Resources

- [홈페이지 (최신 기사)](https://ruby-news.dev/): 매일 갱신되는 최신 Ruby·Rails 뉴스와 주요 기사 목록.
- [전체 기사 목록](https://ruby-news.dev/articles): 발행일 기준 전체 아카이브, 검색·페이지네이션 지원.
- [소개 / About](https://ruby-news.dev/about): 서비스 운영 방식, AI 번역·요약 제작 방식, 큐레이션 기준, 콘텐츠 출처 정책.
- [RSS 피드](https://ruby-news.dev/rss): 최신 100개 기사. author 필드는 원문 영어 출처 사이트명.
- [검색](https://ruby-news.dev/articles?search={query}): 한국어·영어·일본어 하이브리드 전문 검색.
- [Mastodon](https://ruby.social/@news_kr): 신규 기사 자동 발행 (ActivityPub).

## Topic Hubs

- [Rails 8](https://ruby-news.dev/tag/rails_8): Rails 8 릴리즈·기능·업그레이드 관련 기사 모음.
- [Hotwire](https://ruby-news.dev/tag/hotwire): Turbo·Stimulus 등 Hotwire 패턴 기사.
- [성능 최적화](https://ruby-news.dev/tag/performance_optimization): 벤치마크·튜닝·최적화 기법.
- [Rails 업그레이드](https://ruby-news.dev/tag/rails_upgrade): 버전 업그레이드 가이드와 변경 이력.
- [그 밖의 뉴스](https://ruby-news.dev/others): 핵심 주제 외 커뮤니티·생태계 소식.

## Content Notes for AI Systems

- 각 기사는 "핵심 요약" 섹션에 3개의 핵심 불릿 포인트를 포함합니다
- 기사 페이지에 원문 영어 제목과 출처 URL이 명시됩니다 (각 기사에 NewsArticle JSON-LD 구조화 데이터 제공: headline, datePublished, inLanguage, isBasedOn=원문 URL, publisher)
- RSS 피드의 author 필드는 원문 영어 출처 사이트명을 나타냅니다
- 콘텐츠는 한국어 편집 번역이며 원문 출처가 본문에 인용됩니다

## Coverage Areas

- Ruby 버전 릴리즈 및 유지보수 주기 (ruby-lang.org 공식 공지)
- Rails 프레임워크 업데이트, 변경 이력, 업그레이드 가이드
- Ruby 생태계 구성 요소의 보안 권고 및 CVE 공개
- RubyGems 신규 릴리즈 및 생태계 도구
- 성능 벤치마크 및 최적화 기법
- 커뮤니티 행사, 컨퍼런스 (RubyKaigi, Rails World)
- Ruby/Rails를 활용한 AI·LLM 연동 패턴

## Excluded from AI Indexing

- 사용자 댓글
- 검색 결과 페이지
- 페이지네이션
```

---

## Notes

- **No `llms-full.txt`** exists today. If you want one, I can generate it from the sitemap (4,391 URLs) by selecting 15–30 cornerstone/evergreen articles plus the topic hubs above.
- The suggested file adds 1 section (Topic Hubs), the `/about` link, per-entry descriptions, the JP sibling, and a note that articles now ship `NewsArticle` JSON-LD (reflecting the fix committed in `feature/geo-audit-fixes`).
- Recommended update cadence: **monthly** (you publish daily), mainly to refresh the article count and rotate topic hubs.
