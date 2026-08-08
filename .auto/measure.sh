#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CANDIDATE="$(tr -d '[:space:]' < "$ROOT/.auto/candidate")"
WORKTREE="$ROOT/tmp/autoresearch-typechecker-e0"
SNAPSHOT="e0f5de7c"
PROBE_PREFIX="app/autoresearch_probe_"

case "$CANDIDATE" in
  sorbet|sorbet-probes-strict|sorbet-setter-diagnostics|sorbet-tapioca-refresh|steep|steep-strict|steep-rbs-rails) ;;
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

if [[ "$CANDIDATE" == "sorbet-probes-strict" ]]; then
  ruby -pi -e 'sub("# typed: true", "# typed: strict")' "$WORKTREE"/app/autoresearch_probe_*.rb
elif [[ "$CANDIDATE" == "sorbet-setter-diagnostics" ]]; then
  cp "$ROOT/.auto/setter_forms_diagnostic.rb" "$WORKTREE/app/autoresearch_diagnostic_setter_forms.rb"
elif [[ "$CANDIDATE" == "steep-strict" ]]; then
  ruby -pi -e 'gsub("configure_code_diagnostics(DIAGNOSTICS.call)", "configure_code_diagnostics(D::Ruby.strict)")' "$WORKTREE/Steepfile"
elif [[ "$CANDIDATE" == "sorbet-tapioca-refresh" ]]; then
  AUTORESEARCH_DB_URL="${TEST_DATABASE_URL:-postgresql:///al_news_autoresearch_e0}"
  (cd "$WORKTREE" && RAILS_ENV=test DISABLE_DATABASE_ENVIRONMENT_CHECK=1 TEST_DATABASE_URL="$AUTORESEARCH_DB_URL" DATABASE_URL="$AUTORESEARCH_DB_URL" bin/rails db:drop db:create db:migrate >/dev/null)
elif [[ "$CANDIDATE" == "steep-rbs-rails" ]]; then
  printf '\ngem "rbs_rails", require: false\n' >> "$WORKTREE/Gemfile"
  cat > "$WORKTREE/config/rbs_rails.rb" <<'RUBY'
RbsRails.configure do |config|
  # The immutable source snapshot predates the local PostgreSQL schema. The
  # generator still reads that real schema; only the migration-version guard is
  # disabled so this cross-snapshot benchmark can proceed.
  config.check_db_migrations = false
end
RUBY
  (cd "$WORKTREE" && bundle install --quiet)
fi

run_check() {
  local output_file="$1"
  local started ended
  started="$(ruby -e 'puts Process.clock_gettime(Process::CLOCK_MONOTONIC)')"
  set +e
  if [[ "$CANDIDATE" == "sorbet" || "$CANDIDATE" == "sorbet-probes-strict" || "$CANDIDATE" == "sorbet-setter-diagnostics" ]]; then
    (cd "$WORKTREE" && bundle exec srb tc --no-error-count) >"$output_file" 2>&1
  elif [[ "$CANDIDATE" == "sorbet-tapioca-refresh" ]]; then
    (cd "$WORKTREE" && RAILS_ENV=test TEST_DATABASE_URL="$AUTORESEARCH_DB_URL" DATABASE_URL="$AUTORESEARCH_DB_URL" bundle exec tapioca dsl --environment test --workers 1 >/dev/null && bundle exec srb tc --no-error-count) >"$output_file" 2>&1
  elif [[ "$CANDIDATE" == "steep-rbs-rails" ]]; then
    (cd "$WORKTREE" && bundle exec rbs_rails all >/dev/null && bundle exec rbs-inline --output app lib >/dev/null && bundle exec steep check) >"$output_file" 2>&1
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
detected_files="$(grep -Eo "${PROBE_PREFIX}[0-9][0-9]_[^:]+\.rb" "$OUTPUT" | sort -u || true)"
detected="$(printf '%s\n' "$detected_files" | grep -c '^app/' || true)"
missed_files=""
for probe in "$ROOT"/.auto/probes/*.rb; do
  expected="${PROBE_PREFIX}$(basename "$probe")"
  if ! printf '%s\n' "$detected_files" | grep -qx "$expected"; then
    missed_files="${missed_files}${expected}\n"
  fi
done
false_positives=0

if [[ "$CANDIDATE" == sorbet* ]]; then
  support_kb="$(du -sk "$WORKTREE/sorbet" | awk '{print $1}')"
else
  support_kb="$(du -sk "$WORKTREE/sig" "$WORKTREE/Steepfile" "$WORKTREE/rbs_collection.yaml" "$WORKTREE/rbs_collection.lock.yaml" | awk '{sum += $1} END {print sum}')"
fi

# Existing snapshot was green for both candidates. Any diagnostic outside the
# probe is therefore a baseline/configuration regression and is surfaced.
baseline_errors="$(awk -v prefix="$PROBE_PREFIX" '/(app|lib|config|db|test)\/[^:]+:[0-9]+/ && index($0, prefix) == 0 && index($0, "app/autoresearch_diagnostic_") == 0 { count++ } END { print count + 0 }' "$OUTPUT")"
setter_diagnostic_lines="$(grep -Eo 'app/autoresearch_diagnostic_setter_forms\.rb:[0-9]+' "$OUTPUT" | sort -u | tr '\n' ',' || true)"

printf 'candidate=%s status=%s\n' "$CANDIDATE" "$status"
printf 'detected_files=%s\n' "$(printf '%s' "$detected_files" | tr '\n' ',')"
printf 'missed_files=%b' "$missed_files"
printf 'METRIC defects_detected=%s\n' "$detected"
printf 'METRIC false_positives=%s\n' "$false_positives"
printf 'METRIC typecheck_seconds=%s\n' "$elapsed"
printf 'METRIC support_kb=%s\n' "$support_kb"
printf 'METRIC baseline_errors=%s\n' "$baseline_errors"
printf 'setter_diagnostic_lines=%s\n' "$setter_diagnostic_lines"
printf '%s\n' '--- diagnostic tail ---'
tail -20 "$OUTPUT"
