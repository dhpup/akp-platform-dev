# guestbook-kustomize — Kustomize overlays, promotions commit to main

The simplest GitOps promotion model. Each environment is a Kustomize overlay
under `env/<stage>/`, synced by Argo CD **directly from main**. On every
promotion Kargo:

1. clones main,
2. runs `kustomize-set-image` to bump `newTag` in the stage's
   `env/<stage>/kustomization.yaml`,
3. commits and pushes to main,
4. syncs the Argo CD Application.

**Pipeline:** `Warehouse → dev → staging → prod`

**Why choose this pattern:** one branch, no extra machinery — `git log main`
is the complete deployment history, and every environment's desired state is
readable in one file. The natural starting point for teams already doing
"bump the tag in a PR" by hand.

**Things to know**

- The Warehouse is **image-only**. Promotions commit to main, so subscribing
  to main from git would create a promote → new Freight → promote loop. (See
  the comment in `kargo/warehouse.yaml`.)
- The trade-off vs the rendered variant: what actually applies to the cluster
  requires running `kustomize build` mentally or locally; there is no
  plain-YAML branch to inspect.
- Kargo needs git *write* credentials for this project to push to main — see
  the repo root README, step 5.
