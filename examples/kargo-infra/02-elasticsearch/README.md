# Use case 2 — Elasticsearch scale-up and instance replacement (flagship)

**Replaces:** the Rundeck-style job that scales an ES cluster.

This is the flagship because it shows **ordered, health-gated, stateful**
operations a plain GitOps apply cannot do. `kubectl apply` can declare "I want 6
nodes" but cannot *wait for the node to join, trigger a rebalance, and block
until the cluster is green before continuing.* Kargo can, because a promotion is
an ordered sequence of steps with gating between them.

## Modeling: one Stage per managed cluster

A Stage is a lifecycle position, not a reusable job — so there is **one Stage per
managed Elasticsearch cluster**. The reusable sequence is the `scale-up`
`PromotionTask`; each cluster's Stage supplies its own endpoint, node count, and
scoped credentials.

- `es-cluster-dev` — auto-promotes on a desired-state commit (IaC trigger).
- `es-cluster-prod-a`, `es-cluster-prod-b` — **manual** promotion (on-demand,
  gated). Both triggers are demonstrated.

## The sequence — built-in `tf-apply` + shared custom steps

See [`task-scaleup.yaml`](task-scaleup.yaml):

1. **`tf-apply`** (built-in) — provision the new node(s). No external runner.
2. **`es-settings`** (custom) — re-enable shard allocation onto the new node.
3. **`es-wait-green`** (custom) — **block until green with no relocating
   shards.** This is the gate. It uses ES's own
   `_cluster/health?wait_for_status=green&wait_for_no_relocating_shards=true`,
   so the promotion cannot proceed until the cluster is actually healthy; a
   timeout fails the step and stays red/inspectable in the Kargo UI.
4. **Optional replacement** — `es-settings` to exclude the old node, then
   `es-wait-green` again, after which the old node is safe to decommission
   (a follow-up `tf-apply` scaling the module down).

Steps 2–3 are the "this is what Rundeck can't gate cleanly" part. Because the
gate is an in-task step, no separate stage `verification` block is needed.

## Files

```
02-elasticsearch/
  iac/main.tf                   # Terraform the tf-apply step targets (node_count)
  desired-state/clusters.yaml   # node counts per cluster (git source of truth / trigger)
  warehouse.yaml                # git-subscribes to desired-state/
  task-scaleup.yaml             # tf-apply -> es-settings -> es-wait-green (+ optional drain)
  stages.yaml                   # one Stage per managed cluster; endpoint/counts/creds as vars
  project.yaml                  # Project + policy (auto dev cluster, manual prod)
```

Requires the shared library ([`../kargo-shared/`](../kargo-shared/)) and the
`es-credentials-*` / `aws-tf-*` shared secrets.
