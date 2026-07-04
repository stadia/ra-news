# 사이트맵 빌드 순간 메모리 peak 축소

- 날짜: 2026-07-03
- 대상 코드: `app/functions/sitemap_builder.rb`
- 관련: `config/sitemap.rb`, `config/recurring.yml`, `test/functions/sitemap_builder_test.rb`

## 배경 / 문제

`SitemapBuilder.build`는 solid_queue 반복 작업 `sitemap_refresh`(평일 매시 30분,
`config/recurring.yml`)로 **장수명 워커 프로세스 안에서 in-process 실행**된다.

빌드 시 `SitemapGenerator::Sitemap.create`는 링크를 `max_sitemap_links`(기본
50,000)에 도달할 때까지 Link 객체 배열에 쌓았다가 한 번에 디스크로 flush한다.
현재 전체 링크 수가 50k 미만이라 출력이 단일 `sitemap1.xml.gz` 한 파일이고, 이는
**전체 링크 세트를 한 버퍼에 통째로 물고 있다가 flush**한다는 뜻이다. 이 순간
메모리 스파이크 때문에 워커가 OOM으로 죽었고, 임시 대응으로 **워커 컨테이너
메모리 상한을 상향**한 상태다(상한 자체는 배포 리포/인프라 영역).

증상은 누적 팽창이 아니라 **단일 빌드의 순간 스파이크**로 파악되었다.

## 성공 기준

사이트맵 빌드의 **순간(instantaneous) 메모리 peak를 낮춰**, 상향했던 워커
컨테이너 메모리 상한을 다시 낮출 수 있게 한다.

## 접근 분석

순간 peak를 결정하는 유일한 변수는 `SitemapGenerator`가 한 번에 메모리에 쥐는
링크 버퍼 크기다. AR 읽기는 이미 `find_in_batches(500)`으로 배치화되어 있어
peak의 원인이 아니다.

검토했으나 채택하지 않은 접근:

- **A-2 서브프로세스 격리(spawn `rake sitemap:refresh:no_ping`)**: 빌드를 일회용
  자식 프로세스로 분리해 종료 시 OS가 메모리를 회수하는 방식. *누적 팽창
  (sustained)* 문제에는 정답이지만, 빌드 창 동안 **두 번째 Rails를 워커 옆에
  통째로 부팅**하므로 순간 peak를 오히려 키운다. 단일 스파이크 문제에는 부적합.
- **A-1 fork 격리**: COW로 2×-Rails 겹침은 피하지만, 자식 안의 링크 버퍼 크기를
  줄이지 않으면 peak는 in-process와 동일. 버퍼 축소 없이는 스파이크 해결 안 됨.
- **Ractor**: 같은 주소 공간이라 종료해도 OS 메모리 회수가 없고(스파이크에 무익),
  Rails/AR/pg가 Ractor-safe가 아니라 빌드 자체가 불가.
- **직접 스트리밍 XML writer(C)**: 최대 제어권이나 인덱스/hreflang/50k 분할을
  재구현해야 하고 여전히 in-process. 과한 코드량.

## 채택 설계 (접근 B — in-process 버퍼 축소)

`SitemapBuilder.build`의 설정 블록에 한 줄 추가한다.

```ruby
SitemapGenerator::Sitemap.max_sitemap_links = 5_000
```

`sitemap_generator` 7.0.3의 `SitemapGenerator::Sitemap`(기본 LinkSet)은
`max_sitemap_links` accessor를 노출하며, `builder/sitemap_file.rb`의
`@link_count < max_sitemap_links` 체크로 이 개수 도달 시 현재 사이트맵 파일을
finalize(gzip 후 디스크 write)하고 빈 버퍼로 새 파일을 시작한다. 값을 5,000으로
낮추면 메모리에 동시에 존재하는 Link 객체가 50k → 5k로 약 10× 축소되어 순간
peak가 그만큼 내려간다. finalize 시 만들어지는 XML 문자열도 파일당 작아진다.

기존 설정(`compress`, `include_root`, `sitemaps_path`, `default_host`)과 같은
accessor 스타일이라 블록 상단에 자연스럽게 위치한다.

### 바꾸지 않는 것

- `find_in_batches(500)` 유지 (이미 배치화됨).
- `config/recurring.yml` 유지 — in-process 실행 유지, 서브프로세스/fork 없음.
- hreflang alternates / `lastmod_for` / 로케일별 `<url>` 블록 로직 전부 그대로.

## 출력 변화 / SEO 영향

단일 `sitemap1.xml.gz` → `sitemap1.xml.gz … sitemapN.xml.gz` 여러 파일 + 인덱스
`sitemap.xml.gz`가 이들을 참조한다. Google은 사이트맵 인덱스 + 다중 사이트맵을
완전 지원한다(파일당 최대 5만 URL, 인덱스당 최대 5만 사이트맵). SEO 상 손해 없음.
`config/routes.rb`의 `/sitemap.xml → /sitemaps/sitemap.xml.gz`(인덱스) 301
리다이렉트도 그대로 유효하다(인덱스 파일명 불변).

## 테스트

- 기존 `test/functions/sitemap_builder_test.rb`는 전부 `SitemapGenerator`를 stub
  처리하고 파일 개수를 가정하지 않으므로 변경 없이 통과한다.
- `build`가 `max_sitemap_links=`를 5,000으로 설정하는지 확인하는 테스트 1개 추가.

## 검증 (구현 후)

- `5_000`은 시작값이며 튜닝 대상이다. dev DB가 비어 있어 실제 감소폭은 측정 불가.
- 스테이징/프로덕션에서 빌드 중 워커 RSS를 측정해 peak 감소를 확인하고 값을
  조정한다. 값이 낮을수록 peak↓·파일수↑(둘 다 무해 범위).
- `bundle exec rspec`(또는 프로젝트 테스트 러너)로 회귀 확인.

## 트레이드오프 / 남는 리스크

- 워커 baseline의 힙 retention(sustained)은 여전히 남지만, 문제가 순간
  스파이크이므로 목표와 무관하다.
- 5,000에서도 peak가 여전히 높으면(예: 다른 잡과 동시 스파이크) 값을 더 낮추거나,
  그때 비로소 fork 격리를 재검토한다.
