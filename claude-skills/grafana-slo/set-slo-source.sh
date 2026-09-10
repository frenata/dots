#!/usr/bin/env bash
# Set query.ratio.sourceDatasourceUid on a Grafana SLO via the plugin REST API.
# gcx cannot do this: `gcx slo definitions push` silently drops the field, so a
# gcx-created ratio SLO reads its (empty) destination datasource and sits on NODATA.
#
# Usage: set-slo-source.sh <slo-id> [source-datasource-uid]
#   slo-id                the SLO metadata.name / uuid (lowercase alphanumeric)
#   source-datasource-uid where the metrics live; defaults to gmp-us-prod
#
# Idempotent — safe to re-run after any `gcx slo definitions push`.
set -euo pipefail

id="${1:?usage: set-slo-source.sh <slo-id> [source-datasource-uid]}"
src="${2:-gmp-us-prod}"
path="/api/plugins/grafana-slo-app/resources/v1/slo/${id}"

body="$(gcx api "$path" 2>/dev/null | python3 -c '
import sys, json
raw = [l for l in sys.stdin if l.strip().startswith("{")]
if not raw:
    sys.exit("SLO not found: '"$id"'")
s = json.loads(raw[-1])
s.pop("readOnly", None)                       # server-managed; PUT rejects/ignores it
s.setdefault("query", {}).setdefault("ratio", {})["sourceDatasourceUid"] = "'"$src"'"
json.dump(s, sys.stdout)
')"

gcx api -X PUT "$path" -d "$body" >/dev/null

# verify it stuck
got="$(gcx api "$path" 2>/dev/null | python3 -c '
import sys, json
s = json.loads([l for l in sys.stdin if l.strip().startswith("{")][-1])
print(s.get("query", {}).get("ratio", {}).get("sourceDatasourceUid"))
')"

if [ "$got" = "$src" ]; then
  echo "ok: ${id} sourceDatasourceUid=${got}"
else
  echo "FAILED: ${id} sourceDatasourceUid=${got} (wanted ${src})" >&2
  exit 1
fi
