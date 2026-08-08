#!/bin/bash
set -euo pipefail
bash -n .auto/measure.sh
for probe in .auto/probes/*.rb; do ruby -c "$probe" >/dev/null; done
ruby -c .auto/setter_forms_diagnostic.rb >/dev/null
candidate="$(tr -d '[:space:]' < .auto/candidate)"
case "$candidate" in sorbet|sorbet-probes-strict|sorbet-setter-diagnostics|sorbet-tapioca-refresh|steep|steep-strict|steep-rbs-rails) ;; *) exit 1 ;; esac
test "$(find .auto/probes -name '*.rb' | wc -l | tr -d ' ')" -eq 9
test -z "$(git status --porcelain -- app lib config db test spec)"
