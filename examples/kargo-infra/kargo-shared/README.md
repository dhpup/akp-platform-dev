# kargo-shared — a library of custom promotion steps

Reusable `CustomPromotionStep`s shared across all three use cases. This is the
"library of components" primitive: each step is a small, named, OCI-image-backed
action registered **cluster-wide**, then composed into `PromotionTask`s with
per-stage `config`. Modelled on Akuity's `sedemo-platform/kargo-shared`.

```yaml
# How a task uses one (see any use case's task file):
- as: wait-green
  uses: es-wait-green              # <- the custom step's metadata.name
  config:
    endpoint: ${{ vars.esEndpoint }}
    username: ${% sharedSecret('es-credentials').username %}
    password: ${% sharedSecret('es-credentials').password %}
# outputs are read downstream as ${{ task.outputs['<alias>'].<field> }}
```

## Steps in this library

| Step (`uses:`) | Image | Purpose | Outputs |
|----------------|-------|---------|---------|
| `http-probe` | curl | GET a URL and assert the HTTP status (generic health gate) | — |
| `es-settings` | curl | `PUT _cluster/settings` with a JSON body (enable/exclude allocation) | — |
| `es-wait-green` | curl | Block until `_cluster/health` is green with no relocating shards | — |
| `aws-secret-rotate` | aws-cli | Generate a new value and `put-secret-value` | `versionId` |
| `aws-secret-verify` | aws-cli | Assert the live `AWSCURRENT` version matches | — |
| `windows-runbook` | curl | Trigger a Windows deploy/runbook (Octopus-style replacement) | — |

Built-in Terraform steps (`tf-plan`, `tf-apply`, `tf-output`) are used directly
in the tasks — they are not custom steps and need no definition here.

## Requirements (important)

`CustomPromotionStep` and the `tf-*` steps run **pod-based promotions** and are
available on **Kargo on the Akuity Platform (custom steps v1.10+, `tf-*` v1.9+)**,
require the **Promotion Controller**, and use a **self-hosted agent** to run the
step pods. Custom steps are **alpha**. Confirm these are enabled on your instance
before applying.

## Applying the library

Custom steps are cluster-scoped, so apply this directory once to the Kargo
control plane. [`../kargo-shared-app.yaml`](../kargo-shared-app.yaml) is an Argo
CD Application that syncs this dir to the `kargo` destination (same approach as
`sedemo-platform/bootstrap/kargo-shared.yaml`). Or apply directly:

```sh
kubectl apply -f examples/kargo-infra/kargo-shared/   # against the Kargo control plane
```

## Credentials

Steps that call external systems receive credentials as `config` values the task
resolves from **shared secrets** (`${% sharedSecret('name').key %}`). Create
those secrets in Kargo; never hardcode values here. Each task comments which
shared secret it expects.
