# guestbook-helm — Helm chart, promotions commit to main

Argo CD renders the chart in `chart/` **from main**, layering the
per-environment values file `env/<stage>/values.yaml` on top of the chart
defaults (multi-source `$values` pattern — see `argocd/appset.yaml`). On every
promotion Kargo:

1. clones main,
2. runs `yaml-update` to bump `image.tag` in `env/<stage>/values.yaml`,
3. commits and pushes to main,
4. syncs the Argo CD Application.

**Pipeline:** `Warehouse → dev → staging → prod`

**Why choose this pattern:** the natural fit when your apps already ship as
Helm charts and you want per-environment configuration expressed as values
(replicas, resources, feature flags) rather than overlays. Environment diffs
are just values-file diffs on main.

**Things to know**

- The Warehouse is **image-only** — promotions commit to main, and a git
  subscription to main would loop (see `kargo/warehouse.yaml`).
- The per-env values files live *outside* the chart directory, which is why
  the Application uses two sources (`$values` ref). Argo CD cannot reference
  value files outside a single source's path.
- What applies to the cluster requires a `helm template` to inspect; if you
  want plain-YAML visibility, compare with `guestbook-helm-rendered`.
- Kargo needs git *write* credentials for this project to push to main — see
  the repo root README, step 5.
