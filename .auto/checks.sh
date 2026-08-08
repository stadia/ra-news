#!/bin/bash
set -euo pipefail
bash -n .auto/measure.sh
for probe in .auto/probes/*.rb; do ruby -c "$probe" >/dev/null; done
ruby -c .auto/setter_forms_diagnostic.rb >/dev/null
ruby -c .auto/hash_inference_diagnostic.rb >/dev/null
candidate="$(tr -d '[:space:]' < .auto/candidate)"
case "$candidate" in sorbet|sorbet-ci|sorbet-ci-cache-diagnostics|sorbet-ci-regenerated|sorbet-ci-retry|sorbet-current-ci|sorbet-current-ci-regenerated|sorbet-current-product|sorbet-fix-branch|sorbet-fix-ci-regenerated|sorbet-fix-data-shim|sorbet-fix-dsl-refresh|sorbet-fix-latest|sorbet-hash-diagnostics|sorbet-probes-strict|sorbet-setter-diagnostics|sorbet-tapioca-refresh|steep|steep-server|steep-strict|steep-rbs-rails) ;; *) exit 1 ;; esac
test "$(find .auto/probes -name '*.rb' | wc -l | tr -d ' ')" -eq 9
test -z "$(git status --porcelain -- app lib config db test spec)"
