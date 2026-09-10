---
name: grafana-slo
description: Create, edit, and debug Grafana Cloud SLOs via the `gcx` CLI at Overstory, especially ratio SLOs built on GCP/GMP-sourced metrics. Use when the user wants to make an SLO, define an SLI, push/pull SLO definitions, or diagnose an SLO stuck on NODATA. Triggers on "create an SLO", "gcx slo", "SLO shows NODATA", "SLO not populating", "SLI has no data", "add an SLO for <service>".
---

# Grafana SLOs via gcx (Overstory)

`gcx` is the Grafana Cloud CLI, authenticated to `overstory.grafana.net`. It can create SLOs, but it has one trap that silently produces dead SLOs. Read the datasource model first — it's the whole game.

## The datasource model (read this or you will build broken SLOs)

A ratio SLO has **two** datasources, and they are almost never the same here:

- `destinationDatasource.uid` — where the SLO's generated recording rules are **written**. Must be a writable Mimir: **`grafanacloud-prom`**.
- `query.ratio.sourceDatasourceUid` — where the success/total metrics are **read from**. For anything emitted by our Cloud Run services (bosun, apollo-mcp, navigator) or scraped by Google Managed Prometheus, this is **`gmp-us-prod`**.

Our app/OTel metrics (`http_server_duration_*`, `apollo_mcp_*`, `graphql_*`, `run_googleapis_com:*`) live in **GMP, not in `grafanacloud-prom`**. If the query has no source datasource, it runs against the destination (`grafanacloud-prom`), finds nothing, and the SLO sits on **NODATA** forever.

## THE TRAP: `gcx slo definitions push` drops `sourceDatasourceUid`

`gcx`'s YAML schema does not include `query.ratio.sourceDatasourceUid`. If you put it in the YAML, **push silently discards it** — no error, dry-run passes, the SLO is created, and it never gets data. This is the single thing that trips everyone up.

So the workflow is: **create the skeleton with `gcx`, then set the source datasource with the plugin REST API.** Never rely on `gcx push` alone for a GMP-sourced SLO, and never re-push an existing one with `gcx` without re-applying the source (a plain re-push wipes it).

## Workflow

### 1. Write the YAML

`metadata.name` (the SLO id) **must be lowercase alphanumeric — no hyphens/underscores** (a 400 otherwise). `spec.name` is the display name and may be readable.

```yaml
apiVersion: slo.ext.grafana.app/v1alpha1
kind: SLO
metadata:
  name: myserviceerrorrate          # id: [a-z0-9] only
  namespace: stacks-1715653
spec:
  description: "..."
  destinationDatasource:
    uid: grafanacloud-prom           # ALWAYS the writable Mimir
  name: my-service-error-rate        # display name; hyphens OK
  objectives:
  - value: 0.90
    window: 28d
  query:
    ratio:
      successMetric:
        prometheusMetric: apollo_mcp_tool_count_total{faas_name="prod-us-app-apollo-mcp",apollo_mcp_success="true"}
      totalMetric:
        prometheusMetric: apollo_mcp_tool_count_total{faas_name="prod-us-app-apollo-mcp"}
    type: ratio
```

### 2. Dry-run, then push (creates the SLO skeleton)

```sh
gcx slo definitions push my-slo.yaml --dry-run   # validates STRUCTURE only — not id charset, not source
gcx slo definitions push my-slo.yaml
```

### 3. Set the source datasource via the plugin API (the step gcx can't do)

```sh
~/.claude/skills/grafana-slo/set-slo-source.sh myserviceerrorrate gmp-us-prod
```

The script GETs the SLO, drops the server-managed `readOnly` block, sets `query.ratio.sourceDatasourceUid`, and `PUT`s it back. It's idempotent — safe to re-run on every id after any `gcx push`.

### 4. Verify it actually computes (don't trust "created")

Recording rules take a few minutes. Then:

```sh
gcx slo definitions status --json name,objective,status
# and the actual SLI value:
gcx metrics query -d grafanacloud-prom 'grafana_slo_sli_window{grafana_slo_uuid="myserviceerrorrate"}'
```

`status: OK` with a real `grafana_slo_sli_window` value = working. Persisted `NODATA` after ~10 min = source datasource is wrong (see Diagnosis).

## Diagnosing NODATA

Query `grafanacloud-prom` (rules always land there regardless of source):

- `grafana_slo_info{grafana_slo_uuid="..."}` **present** but `grafana_slo_sli_window{...}` **absent** → the SLI query returns nothing → **`sourceDatasourceUid` is unset or wrong.** This is the usual cause. Fix with step 3.
- Confirm the raw metric exists where you think: `gcx metrics list-names -d gmp-us-prod --contains '<metric>'`.
- Confirm the SLO's stored source: `gcx api "/api/plugins/grafana-slo-app/resources/v1/slo/<id>" | jq '.query.ratio.sourceDatasourceUid'` (gcx's own `slo definitions get` does **not** show this field).

## Checking metric baselines (before setting objectives)

Our Cloud Run services scale to zero and mint a new series per instance, so counters are **sparse and churn**. An instant `count(metric)` returns empty when nothing scraped recently — it is NOT proof the metric is missing. Always range over the SLO window:

```sh
# right (churn-proof):
gcx metrics query -d gmp-us-prod 'sum(increase(apollo_mcp_tool_count_total{...}[28d]))'
gcx metrics query -d gmp-us-prod 'sum(max_over_time(apollo_mcp_tool_count_total{...}[28d])) by (...)'
# misleading (misses sparse series):
gcx metrics query -d gmp-us-prod 'count(apollo_mcp_tool_count_total)'
```

Note: Grafana's SLO ratio uses `rate()` internally, which is also churn-sensitive, so the live `grafana_slo_sli_window` can read a few points below your `increase[28d]` baseline, especially in the first hours while the window fills.

## Objective strategy

Grafana has no SLI-without-an-SLO. To track an indicator without committing to a target, set the objective **just under the observed baseline so it trivially passes**, then ratchet up over time. Set the objective from a churn-proof baseline (above), not the noisy fresh SLI.

## Scoping SLIs (Overstory-specific lessons)

- **Exclude client-caused status from health SLIs.** For bosun, HTTP `4xx` is ~all `401` (unauthenticated callers) and ~92% of traffic is `GET 307` health-check redirects — scope to `http_method="POST"` and treat only `5xx` as unhealthy. Don't blacklist `3xx` on principle; scope by method to drop the probe traffic.
- **GraphQL returns 200 on errors.** True bosun error rate needs the `graphql_errors_total{code}` / `graphql_operations_total` metrics (operation-level), not HTTP status. See REX-175.
- **apollo-mcp emits no `http_server_duration`** — its HTTP availability comes only from `run_googleapis_com:request_count{response_code_class}`; tool-level success is `apollo_mcp_tool_count_total{apollo_mcp_success}`.

## Folders

**SLOs have no folder attribute** — you cannot "put an SLO in a folder." Only the auto-generated drill-down dashboards (`grafana_slo_app-<id>`) are folder-scoped, and the plugin creates them in its own **Grafana SLO** folder. To group them with a team's dashboards, move those dashboards (POST `/api/dashboards/db` with `folderUid`, `overwrite:true`). The plugin may recreate/revert them when the SLO is edited — re-check after changes.

## GitOps caveat

Because `gcx push` drops `sourceDatasourceUid`, the pulled YAML is **not** a faithful source of truth for GMP-sourced SLOs. A `gcx slo definitions pull`/`push` round-trip will silently strip the source and break every SLO it touches. Manage `sourceDatasourceUid` through the plugin API/UI, and if you keep YAML in git, treat the source-datasource step as a required post-push action (the helper script is idempotent — safe to re-run on all ids).
