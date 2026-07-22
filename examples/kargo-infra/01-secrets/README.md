# Use case 1 — Secrets update workflow (AWS Secrets Manager)

**Replaces:** a Rundeck-style secrets rotation/update job.

**Rundeck → Kargo mapping:** the opaque "run the rotate-secret job" becomes a
git-committed change to a **declarative secret definition** (name, metadata, and
a *reference* to where the value comes from — never the raw value), promoted
through `dev → staging → prod`. Each stage runs the same reusable steps with
per-env account/region/path and scoped credentials. Visibility: every rotation
is a Freight with a diff and a promotion record. Gating: dev auto-promotes;
staging and prod are manual; and a verify step confirms the new secret version
is actually live before a stage is healthy.

## Two implementations — pick one

- **(a) Custom steps (default)** — [`tasks.yaml`](tasks.yaml): composes two
  library steps, `aws-secret-rotate` then `aws-secret-verify`. The rotate step
  generates a new value server-side (`get-random-password`) and calls
  `put-secret-value`; the verify step reads back the live `AWSCURRENT` version
  and **fails the promotion if it doesn't match**. All signed AWS calls happen
  inside the `aws-cli` step pod with per-stage scoped creds — no `http` proxy,
  no SigV4 to hand-roll.
- **(b) GitOps via External Secrets Operator** —
  [`tasks-eso.yaml`](tasks-eso.yaml): the promotion syncs an `ExternalSecret`
  (via `argocd-update`) and lets ESO reconcile the value from the backing store.
  Kargo never touches AWS. Use this when ESO is available.

## What has access to what

- Kargo reads the **definitions repo** (secret *definitions*, no values).
- Option (a): each stage's `aws-secret-rotate`/`-verify` step gets **scoped AWS
  creds** from a per-env shared secret (`aws-rotation-dev/-staging/-prod`) —
  passed as step config, injected as env, never in git.
- Option (b): ESO holds the SecretStore credential; Kargo only syncs a manifest.
- **No raw secret value is ever in git, in Freight, or in a manifest.**

## Files

```
01-secrets/
  secret-defs/example-app-secrets.yaml  # declarative definitions (names/metadata/refs)
  warehouse.yaml                         # git-subscribes to secret-defs/
  tasks.yaml                             # option (a): aws-secret-rotate -> aws-secret-verify
  tasks-eso.yaml                         # option (b): sync ExternalSecret, ESO reconciles
  eso/dev/externalsecret.yaml            # sample ExternalSecret for option (b)
  stages.yaml                            # dev/staging/prod; per-env region/path + shared-secret creds
  project.yaml                           # Project + auto-dev/manual-prod policy
```

Requires the shared library ([`../kargo-shared/`](../kargo-shared/)) applied to
the Kargo control plane, plus the `aws-rotation-*` shared secrets.
