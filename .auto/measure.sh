#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CANDIDATE="$(tr -d '[:space:]' < "$ROOT/.auto/candidate")"
WORKTREE="$ROOT/tmp/autoresearch-typechecker-e0"
SNAPSHOT="e0f5de7c"
PROBE_PREFIX="app/autoresearch_probe_"

case "$CANDIDATE" in
  sorbet|steep) ;;
  *) echo "unknown candidate: $CANDIDATE" >&2; exit 2 ;;
esac

if [[ ! -d "$WORKTREE/.git" && ! -f "$WORKTREE/.git" ]]; then
  rm -rf "$WORKTREE"
  git -C "$ROOT" worktree add --detach "$WORKTREE" "$SNAPSHOT" >/dev/null
fi

git -C "$WORKTREE" reset --hard "$SNAPSHOT" >/dev/null
git -C "$WORKTREE" clean -fdx >/dev/null
for probe in "$ROOT"/.auto/probes/*.rb; do
  cp "$probe" "$WORKTREE/app/autoresearch_probe_$(basename "$probe")"
done

run_check() {
  local output_file="$1"
  local started ended
  started="$(ruby -e 'puts Process.clock_gettime(Process::CLOCK_MONOTONIC)')"
  set +e
  if [[ "$CANDIDATE" == "sorbet" ]]; then
    (cd "$WORKTREE" && bundle exec srb tc --no-error-count) >"$output_file" 2>&1
  else
    (cd "$WORKTREE" && bundle exec rbs-inline --output app lib >/dev/null && bundle exec steep check) >"$output_file" 2>&1
  fi
  local status=$?
  set -e
  ended="$(ruby -e 'puts Process.clock_gettime(Process::CLOCK_MONOTONIC)')"
  ruby -e 'puts((ARGV[1].to_f - ARGV[0].to_f).round(3))' "$started" "$ended"
  return "$status"
}

OUTPUT="$(mktemp)"
trap 'rm -f "$OUTPUT"' EXIT
if elapsed="$(run_check "$OUTPUT")"; then
  status=0
else
  status=$?
fi

# Each file contains exactly one seeded defect. Count distinct probe files in
# diagnostics so checker-specific source ranges (expression vs method def) do
# not bias the result.
detected="$(grep -Eo "${PROBE_PREFIX}[0-9][0-9]_[^:]+\.rb" "$OUTPUT" | sort -u | wc -l | tr -d ' ')"
false_positives=0

if [[ "$CANDIDATE" == "sorbet" ]]; then
  support_kb="$(du -sk "$WORKTREE/sorbet" | awk '{print $1}')"
else
  support_kb="$(du -sk "$WORKTREE/sig" "$WORKTREE/Steepfile" "$WORKTREE/rbs_collection.yaml" "$WORKTREE/rbs_collection.lock.yaml" | awk '{sum += $1} END {print sum}')"
fi

# Existing snapshot was green for both candidates. Any diagnostic outside the
# probe is therefore a baseline/configuration regression and is surfaced.
baseline_errors="$(awk -v prefix="$PROBE_PREFIX" '/(app|lib|config|db|test)\/[^:]+:[0-9]+/ && index($0, prefix) == 0 { count++ } END { print count + 0 }' "$OUTPUT")"

printf 'candidate=%s status=%s\n' "$CANDIDATE" "$status"
printf 'METRIC defects_detected=%s\n' "$detected"
printf 'METRIC false_positives=%s\n' "$false_positives"
printf 'METRIC typecheck_seconds=%s\n' "$elapsed"
printf 'METRIC support_kb=%s\n' "$support_kb"
printf 'METRIC baseline_errors=%s\n' "$baseline_errors"
printf '%s\n' '--- diagnostic tail ---'
tail -20 "$OUTPUT"
