# Use case 3 — VM deployment (Terraform), with a Windows/Octopus replacement note

**Replaces:** a Rundeck-style scheduler + an Octopus-style Windows/VM delivery
tool for a fleet of a few hundred VMs (Linux and Windows; Active Directory and
MS SQL are the long-term Windows survivors).

## Model

- A Warehouse subscribes to the **IaC repo** (Terraform). A commit → Freight.
- **Stages are the env/region progression:** `dev → staging → prod`, plus a
  separate **isolated GovCloud/FedRAMP-style stage** with **manual approval** and
  **distinct credentials** (a separate shared secret).
- The reusable `terraform` `PromotionTask` runs built-in **`tf-plan` then
  `tf-apply`**, captures the plan for visibility, and post-verifies reachability
  with the shared **`http-probe`** step.
- **Gating:** `dev`/`staging` auto-promote; **`prod` and `govcloud` are manual**
  (a human approves the Freight before the apply runs). GovCloud swaps in
  isolated credentials.

## Both triggers

- **IaC path (auto):** commit to the IaC repo → Freight → dev auto-applies.
- **On-demand path (manual):** promote existing Freight into prod/govcloud by
  hand — the Rundeck-style "run it now," gated and audited.

## Steps used (no `http`-to-runner indirection)

Terraform runs via the built-in `tf-plan` / `tf-apply` steps directly inside the
promotion — no external runner. The only HTTP is the deliberate `http-probe`
health gate. Credentials come from shared secrets (`aws-tf-*`), injected into the
step as env, never hardcoded.

## Octopus / Windows replacement (same model, swap one step)

The Windows fleet (AD, MS SQL) moves off the Octopus-style tool with the **same
stage-per-lifecycle model** — only the step changes: instead of `tf-apply`, the
promotion calls the shared **`windows-runbook`** custom step, which triggers the
Windows deploy/runbook API; `http-probe` then confirms the Windows service is up.
Same stages, same manual approval on prod, same audit trail — so Linux/Terraform
and Windows/runbook are one model with a swapped step, consolidating two legacy
tools.

## Tie infra and app together (`infra-then-app/`)

A single pipeline where creating an infra dependency (an S3 bucket) **precedes**
an app deploy, gated on infra health, then the whole unit promotes together. See
[`infra-then-app/bundle.yaml`](infra-then-app/bundle.yaml): `tf-apply` (bucket) →
`tf-output` → `http-probe` (gate) → `argocd-update` (app), as one atomic,
ordered, gated promotion per environment.

## Files

```
03-vm-terraform/
  iac/main.tf, iac/dev.tfvars   # Terraform the tf-plan/tf-apply steps target
  warehouse.yaml                # git-subscribes to iac/
  task-terraform.yaml           # tf-plan -> tf-apply -> http-probe; creds by var
  stages.yaml                   # dev/staging/prod + isolated govcloud (manual, distinct creds)
  project.yaml                  # Project + policy (auto dev/staging, manual prod/govcloud)
  infra-then-app/               # S3-before-app bundle (tf-apply -> tf-output -> probe -> deploy)
```

Requires the shared library ([`../kargo-shared/`](../kargo-shared/)) and the
`aws-tf-*` shared secrets.
