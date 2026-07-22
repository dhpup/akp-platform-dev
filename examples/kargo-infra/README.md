# Kargo for infrastructure lifecycle orchestration

Three examples showing Kargo driving **infrastructure** workflows — not just
Kubernetes app delivery. The framing is a customer moving off a legacy job
scheduler (Rundeck-style) for infra jobs and a Windows/VM deploy tool
(Octopus-style) for VM delivery, and evaluating whether Kargo's gated,
auditable, modular promotions can replace them.

## Approach: a shared library of custom steps + built-in Terraform steps

The reusable logic lives in **custom promotion steps** — small, named,
OCI-image-backed actions registered cluster-wide in
[`kargo-shared/`](kargo-shared/) and composed into `PromotionTask`s with
per-stage `config`. This is the concrete "infra as a library of components"
answer: a stage reads as a short list of named steps, not an opaque script.

- **`kargo-shared/`** — `CustomPromotionStep` definitions (`http-probe`,
  `es-settings`, `es-wait-green`, `aws-secret-rotate`, `aws-secret-verify`,
  `windows-runbook`), synced cluster-wide once via
  [`kargo-shared-app.yaml`](kargo-shared-app.yaml). Same pattern as Akuity's
  `sedemo-platform/kargo-shared`.
- **Built-in `tf-plan` / `tf-apply` / `tf-output`** steps run Terraform directly
  inside promotions — no external runner, no `http` indirection.

Earlier drafts leaned on `http` steps to reach external runners; custom steps +
`tf-*` remove almost all of that. The only remaining HTTP is the deliberate
`http-probe` health gate and the `windows-runbook` trigger (which genuinely is
an API call).

## Requirements

Custom steps and `tf-*` steps use **pod-based promotions** on **Kargo on the
Akuity Platform** (custom steps v1.10+, `tf-*` v1.9+), require the **Promotion
Controller**, and run step pods on a **self-hosted agent**. Custom steps are
**alpha**. Confirm these are enabled before applying (`kubectl get crd | grep
kargo`; check that `CustomPromotionStep` — `ee.kargo.akuity.io/v1alpha1` — exists).

## Modeling rules (applied throughout)

- **A Stage is a lifecycle position, not a reusable job.** One stage per real
  lifecycle (per env, per region, per managed cluster). Reusable logic is a
  custom step, invoked from a `PromotionTask`.
- **Modularity over monolith.** Each pipeline is a composition of small, named
  steps — the opposite of an opaque Rundeck job.
- **Parameterize per env/region** via stage variables ({dev, staging, prod} ×
  {us-east-1, us-west-2} plus an isolated GovCloud/FedRAMP-style env).
- **Both triggers:** git-commit-driven auto-promotion (IaC path) AND
  manually-triggered promotion (on-demand job path).
- **Gating + blast radius:** ordered progression; manual approval on prod-tier /
  isolated stages. Never "deploy everywhere at once."
- **Secrets never hardcoded:** every credential is resolved from a shared secret
  (`${% sharedSecret('name').key %}`) and passed into a step as config.

## The three examples

| # | Example | Replaces | Reusable steps used | The gate |
|---|---------|----------|---------------------|----------|
| 1 | [`01-secrets`](01-secrets/) | Rundeck-style secrets rotation | `aws-secret-rotate`, `aws-secret-verify` (or ESO git path) | read-back that the new version is live |
| 2 | [`02-elasticsearch`](02-elasticsearch/) | Rundeck-style ES scale-up | `tf-apply`, `es-settings`, `es-wait-green` | block until cluster green + no relocating shards |
| 3 | [`03-vm-terraform`](03-vm-terraform/) | Rundeck + Octopus-style VM delivery | `tf-plan`, `tf-apply`, `tf-output`, `http-probe`, `windows-runbook` | manual approval + post-apply reachability |

Assumptions surfaced (correct me if wrong): Terraform is the infra provisioning
tool; External Secrets Operator is available for the git-driven secrets path; the
region/env axis is {dev, staging, prod} × {us-east-1, us-west-2} plus an isolated
GovCloud env.

> These live under `examples/` so the bootstrap ApplicationSets (which only
> discover `apps/*`) never auto-deploy them. Apply the shared library and a use
> case deliberately once the Akuity Platform prerequisites and credentials exist.
