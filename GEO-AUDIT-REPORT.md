# GEO Audit Report: Ruby-News

**Audit Date:** 2026-06-02
**URL:** https://ruby-news.dev
**Business Type:** Publisher (Korean-language Ruby/Rails news aggregator, AI-assisted translation)
**Pages Analyzed:** Homepage, `/about`, 2 article pages, `robots.txt`, `llms.txt`, `sitemap.xml.gz` (4,391 URLs indexed)

---

## Executive Summary

**Overall GEO Score: 63/100 (Fair)**

Ruby-News has an unusually strong *foundation* for AI visibility — a polished bilingual `llms.txt`, full server-side rendering, rich homepage structured data, and a near-ideal citation format on every article (a 3-bullet "핵심 요약" summary plus an explicit source-attribution link). It is held back by two things: (1) a deliberate-but-contradictory crawler posture that blocks the major AI bots (GPTBot, ClaudeBot, CCBot, Google-Extended) while shipping an `llms.txt` that invites AI citation, and (2) **article pages carry no `NewsArticle`/`Article` JSON-LD at all**, even though the homepage is schema-rich and every datum the schema needs (title, publish/modify dates, source URL) is already on the page.

The single highest-leverage fix is adding `NewsArticle` schema to the article template — it is pure upside, the data already exists, and it lifts your weakest category across 4,391 pages at once.

### Score Breakdown

| Category | Score | Weight | Weighted |
|---|---|---|---|
| AI Citability | 78/100 | 25% | 19.5 |
| Brand Authority | 45/100 | 20% | 9.0 |
| Content E-E-A-T | 62/100 | 20% | 12.4 |
| Technical GEO | 70/100 | 15% | 10.5 |
| Schema & Structured Data | 55/100 | 10% | 5.5 |
| Platform Optimization | 58/100 | 10% | 5.8 |
| **Overall GEO Score** | | | **63/100** |

---

## Critical Issues (Fix Immediately)

**None.** No domain-level `noindex`, no 5xx on key pages, content is fully server-rendered and indexable, and structured data is present (on the homepage). Nothing is actively breaking discoverability.

---

## High Priority Issues (Fix Within 1 Week)

### H1 — Article pages have zero Article/NewsArticle schema
Both sampled article pages returned **0 JSON-LD blocks** (homepage has 3). Articles are your primary content type and the entire reason the site exists, yet AI systems and Google receive no machine-readable signal for headline, dates, language, publisher, or original source. All required fields already exist on the page as Open Graph / `<time>` tags:
- `article:published_time` → `2026-06-01T00:19:59+09:00`
- `article:modified_time` → `2026-06-01T08:50:01+09:00`
- `og:type` = `article`, plus an explicit `SOURCE` link to the English original.

This is the audit's #1 recommendation: it is zero-risk, the data is already computed, and it improves 4,391 pages simultaneously. See the ready-to-use template in the Schema deep-dive below.

### H2 — `llms.txt` invites AI citation, but `robots.txt` blocks the major AI crawlers
Your `llms.txt` is excellent and explicitly courts AI systems ("Content Notes for AI Systems", source-URL provenance, summary structure). But `robots.txt` blocks **GPTBot, ClaudeBot, anthropic-ai, CCBot, Google-Extended, Amazonbot, Applebot-Extended, Bytespider, meta-externalagent**, allowing only **PerplexityBot**. This is an intentional "allow search/citation, block training" stance (`Content-Signal: search=yes, ai-train=no`) — defensible — but the execution sends mixed signals and leaves citation reach narrower than your `llms.txt` implies. See the Technical deep-dive for the precise bot-by-bot reality and a recommended robots.txt.

### H3 — `robots.txt` is duplicated and internally contradictory
The file contains a Cloudflare-managed block **and** a second hand-written block, with `GPTBot`, `CCBot`, `Google-Extended`, and `ClaudeBot` each declared twice, plus two separate `User-agent: *` groups. Duplicate/again-listed agents and split `*` groups are fragile and hard to reason about. Consolidate into one authoritative file.

---

## Medium Priority Issues (Fix Within 1 Month)

- **M1 — No `ai-input` content signal.** `Content-Signal` declares `search=yes, ai-train=no` but is silent on `ai-input` (RAG/grounding/real-time AI answers). Since you *want* citation (you allow PerplexityBot and ship `llms.txt`), declare `ai-input=yes` to make the intent explicit and consistent.
- **M2 — Homepage has no `<h1>`.** The homepage renders only `<h2>` headings. Add a single semantic `<h1>` (e.g. "Ruby·Rails 개발자를 위한 한국어 AI 뉴스") for both accessibility and topical clarity to crawlers.
- **M3 — No author/editorial entity on articles.** Content is AI-translated with no byline. For E-E-A-T, model the article `author` as the original source `Organization` and `publisher` as Ruby-News, and use `isBasedOn` to point at the English original (handled by the schema template in H1).
- **M4 — Thin brand-entity footprint.** `sameAs` covers Mastodon, X, and ActivityPub (good), but there is no Wikipedia/Wikidata entity and limited third-party mention volume. Niche-appropriate, but it caps Brand Authority.

---

## Low Priority Issues (Optimize When Possible)

- **L1 — Opaque article slugs.** Some URLs are raw YouTube IDs (`/articles/sjuCiIdMe_4`, `/articles/M25fETp83jQ`). Descriptive slugs read better to humans and AI link parsers.
- **L2 — Generic homepage meta description.** "최신 Ruby, Rails 관련 뉴스와 트렌드를 한곳에서 만나보세요" is fine but undifferentiated; mention the AI-translation + daily-summary angle and article count.
- **L3 — `NewsMediaOrganization.masthead`** points to `/about`, which is good — keep `/about` rich (it already discloses methodology well).

---

## Category Deep Dives

### AI Citability — 78/100
**This is the site's strongest practical asset.** Every article opens with a "핵심 요약" block of exactly three self-contained bullet points — the single most citation-friendly format an AI can encounter (extractable, factual, complete-on-their-own). Example, verbatim from `/articles/implementing-account-specific-rate-limits-in-rails`:

> • rack-attack gem의 throttle 기능을 활용해 계정별로 서로 다른 처리율 제한을 적용할 수 있다.
> • limit 옵션에 proc을 전달하여 요청마다 데이터베이스나 캐시에서 해당 계정의 특정 제한 수치를 동적으로 가져오도록 구성한다.
> • Redis나 Rails.cache로 계정별 제한 수치를 캐싱하여 매 요청 DB 조회를 방지하고 성능을 최적화한다.

Plus: descriptive `<h1>`, clean heading hierarchy (1×h1, 3×h2, 9×h3), explicit `SOURCE` attribution, and full SSR so the text is present without JS. The only reasons this isn't 90+: no `NewsArticle` schema to certify the passage as quotable, and the crawler blocking (H2) limits which engines can actually fetch it.

### Brand Authority — 45/100
`sameAs` is well-formed: `ruby.social/@news_kr` (Mastodon), `x.com/rubynewskr` (X), and an ActivityPub actor (`/@bot`) — the Fediverse federation is a genuine, underrated authority signal. However, web search surfaces sibling domains (`ruby-news.kr`, `ruby-news.jp`) and competing Korean Ruby resources (`rubyonrails.kr`, `rubykr.github.io`) rather than independent third-party mentions of the *Ruby-News* brand, and there is no Wikipedia/Wikidata entity. For a niche, single-operator aggregator this is expected, but third-party mention volume is what AI models weigh most heavily for entity trust.

### Content E-E-A-T — 62/100
**Trustworthiness is handled honestly** — the `/about` page openly discloses that articles are AI-translated, warns about possible mistranslation, and directs readers to the original source for critical decisions. Every article cites its English source URL, and content is updated daily (article modified just hours before audit). The gap is **Experience/Expertise**: no named human editor or contributor credentials, and the value-add is translation+summarization rather than original reporting. Modeling source attribution in schema (publisher vs. original author) and keeping the transparent methodology page are the right moves.

### Technical GEO — 70/100
Strong fundamentals: full SSR (`x-runtime: 0.099s`), HTTP/2 with 103 Early Hints and speculation rules, HSTS (2yr, includeSubDomains), `X-Content-Type-Options: nosniff`, `X-Frame-Options: SAMEORIGIN`, `Referrer-Policy`, canonical tags, `hreflang` (ko / ja→ruby-news.jp / x-default), gzipped sitemap with 4,391 URLs, and a high-quality `llms.txt`. The deductions are entirely the **AI-crawler posture**. Precise bot-by-bot reality as of mid-2026:

| Crawler | Purpose | Status in your robots.txt | GEO effect |
|---|---|---|---|
| GPTBot | OpenAI training **+ some retrieval** | **Blocked** | Reduces ChatGPT reach |
| OAI-SearchBot | ChatGPT Search citation surfacing | Allowed (via `*`) | ✅ ChatGPT *search* citations still possible |
| ChatGPT-User | User-triggered browsing | Allowed (via `*`) | ✅ Works |
| ClaudeBot / anthropic-ai | Anthropic training/general | **Blocked** | Reduces Claude reach |
| Claude-User / Claude-SearchBot | Claude user/search citation | Allowed (via `*`) | ✅ Claude citations still possible |
| Google-Extended | Gemini/Vertex grounding & training | **Blocked** | ❌ Limits Gemini grounding (AI Overviews via Googlebot index still works) |
| PerplexityBot | Perplexity index/citation | **Explicitly allowed** | ✅ Full Perplexity visibility |
| CCBot | Common Crawl (feeds many models) | **Blocked** | Reduces long-tail training presence (intentional) |

**Net:** Your "block training, allow citation" intent is *mostly* achievable because the citation-specific bots (`OAI-SearchBot`, `Claude-SearchBot`, `*-User`, `PerplexityBot`) fall under the permissive `User-agent: *  Allow: /`. The risk is that blocking the umbrella bots (GPTBot/ClaudeBot) historically also dampened citation in those ecosystems, and the duplicated file makes the policy fragile (H3). Decision point: if you want maximum citation, stop blocking GPTBot/ClaudeBot and rely on `Content-Signal: ai-train=no` to express the training opt-out; if training-opt-out is the priority, keep the blocks but add `ai-input=yes` and accept narrower ChatGPT/Claude reach.

### Schema & Structured Data — 55/100
**Homepage: excellent.** Three valid JSON-LD blocks:
- `WebSite` + `SearchAction` (enables AI/Google search box understanding)
- `NewsMediaOrganization` with `logo`, `sameAs` (Mastodon/X/ActivityPub), `masthead`
- `ItemList` of the 12 latest articles

**Article pages: nothing (0 blocks).** This single gap is the whole reason the category sits at 55 instead of 85. Recommended template (every field maps to data already on the page):

```json
{
  "@context": "https://schema.org",
  "@type": "NewsArticle",
  "headline": "Rails에서 계정별 동적 처리율 제한(Rate Limit) 구현하기",
  "inLanguage": "ko",
  "datePublished": "2026-06-01T00:19:59+09:00",
  "dateModified": "2026-06-01T08:50:01+09:00",
  "url": "https://ruby-news.dev/articles/implementing-account-specific-rate-limits-in-rails",
  "mainEntityOfPage": "https://ruby-news.dev/articles/implementing-account-specific-rate-limits-in-rails",
  "description": "Nginx나 CDN의 전역 설정 대신 rack-attack gem의 throttle 기능을 활용해 계정별로 서로 다른 처리율 제한을 적용할 수 있다.",
  "image": "https://assets.ruby-news.dev/assets/og_main-a3af1c9c.png",
  "publisher": {
    "@type": "NewsMediaOrganization",
    "name": "Ruby-News",
    "logo": { "@type": "ImageObject", "url": "https://ruby-news.dev/icon.png" }
  },
  "isBasedOn": "<ORIGINAL_ENGLISH_SOURCE_URL>",
  "translationOfWork": "<ORIGINAL_ENGLISH_SOURCE_URL>"
}
```
> Render this in the article Phlex view/layout, populating from the `Article` record's existing title, `published_time`, `modified_time`, summary, and source URL. Consider adding a `FAQPage` block when an article's "핵심 요약" naturally reads as Q&A.

### Platform Optimization — 58/100
- **Perplexity: strong** — explicitly allowed; your summary-first format is ideal for Perplexity answer cards.
- **ChatGPT Search / Claude: moderate** — reachable via user/search bots, but the umbrella-bot blocks leave reach below potential.
- **Google AI Overviews: works** (uses the Googlebot index, which is unblocked); **Gemini grounding: limited** by the `Google-Extended` block.
- **Fediverse: a real edge** — ActivityPub actor + Mastodon presence distributes content into a network increasingly sampled by AI systems and human curators.
- **RSS:** `/rss` is present and discoverable via `<link rel="alternate">` — good for aggregator ingestion.

---

## Quick Wins (Implement This Week)

1. **Add `NewsArticle` JSON-LD to the article template** (H1) — biggest single GEO lift; data already exists; touches all 4,391 pages.
2. **Add `ai-input=yes` to the `Content-Signal`** (M1) — one line; makes your citation intent explicit and consistent with allowing PerplexityBot + shipping `llms.txt`.
3. **De-duplicate `robots.txt`** (H3) — collapse to one authoritative block; remove the doubled GPTBot/CCBot/ClaudeBot/Google-Extended entries and the second `User-agent: *` group.
4. **Add a semantic `<h1>` to the homepage** (M2).
5. **Decide and document the crawler policy** (H2) — pick "max citation" (unblock GPTBot/ClaudeBot, rely on `ai-train=no`) or "training opt-out" (keep blocks + `ai-input=yes`), and make robots.txt reflect it cleanly.

## 30-Day Action Plan

### Week 1: Schema & robots hygiene
- [ ] Ship `NewsArticle` JSON-LD in the article layout (H1)
- [ ] Validate output against Google Rich Results Test + schema.org validator
- [ ] Rewrite `robots.txt`: single source of truth, add `ai-input=yes`, remove duplicates (H3/M1)

### Week 2: Crawler policy & homepage
- [ ] Finalize crawler stance (H2) and align robots.txt + `llms.txt` wording
- [ ] Add homepage `<h1>` (M2); differentiate homepage meta description (L2)
- [ ] Confirm `OAI-SearchBot` / `Claude-SearchBot` / `Claude-User` remain permitted

### Week 3: E-E-A-T & entity signals
- [ ] Add `author` (source Organization) + `isBasedOn` to article schema (M3)
- [ ] Create a Wikidata item for Ruby-News; keep `sameAs` in sync (M4)
- [ ] Keep `/about` methodology page current (it's a genuine trust asset)

### Week 4: Long-tail polish & measurement
- [ ] Generate descriptive slugs for YouTube-ID articles going forward (L1)
- [ ] Add optional `FAQPage` schema where "핵심 요약" reads as Q&A
- [ ] Baseline AI-referral traffic (Perplexity, ChatGPT, Gemini) to measure impact of the schema/robots changes

---

## Appendix: Pages Analyzed

| URL | Type | Notable GEO Findings |
|---|---|---|
| `/` | Homepage | 3 JSON-LD blocks ✅, OG/Twitter ✅, hreflang ✅, **no `<h1>`** |
| `/robots.txt` | Config | Blocks GPTBot/ClaudeBot/CCBot/Google-Extended; allows PerplexityBot; **duplicated blocks** |
| `/llms.txt` | Config | Present, detailed, bilingual ✅ (excellent) |
| `/sitemaps/sitemap.xml.gz` | Sitemap | 4,391 URLs, gzipped, valid `urlset` ✅ |
| `/about` | Page | Transparent AI-translation methodology ✅ (good Trust signal) |
| `/articles/implementing-account-specific-rate-limits-in-rails` | Article | Summary bullets ✅, source link ✅, dates ✅, **0 schema** |
| `/articles/migrating-from-sidekiq-to-solid-queue` | Article | `article:published/modified_time` ✅, **0 schema** |

---

*GEO methodology: weighted composite across AI Citability (25%), Brand Authority (20%), Content E-E-A-T (20%), Technical GEO (15%), Schema (10%), Platform Optimization (10%). Crawler-access analysis reflects the OpenAI/Anthropic/Google/Perplexity bot taxonomy as of mid-2026.*
