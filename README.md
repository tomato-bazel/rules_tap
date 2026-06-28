# rules_tap

The **public** Bazel surface for [tap](https://github.com/fastverk/tap) — SAVVI's Test Automation
Platform (change-based test selection, target-graph impact analysis, flake tracking, culprit-finding).

This repo ships only the thin Starlark rules + the **prebuilt `tap` CLI** (fetched per-arch from this
repo's GitHub release assets). The engine, gRPC server/daemon, proto contracts, and deploy stay
**private** in `fastverk/tap`. Consumers resolve `rules_tap` anonymously — no access to the private
source — exactly how `rules_lang` ships prebuilt atlas oleans for the private `aion/polyglot` engine.

## Install

`.bazelrc`:

```
common --registry=https://raw.githubusercontent.com/fastverk/bazel-registry/main/
common --registry=https://bcr.bazel.build/
```

`MODULE.bazel`:

```python
bazel_dep(name = "rules_tap", version = "0.0.1")
```

## Use

**Test-authoring rules** — tag/shard tests and define the cacheable test universe:

```python
load("@rules_tap//bazel:defs.bzl", "tap_test_attrs", "tap_test_universe")

ts_test(name = "node_test", srcs = [...], **tap_test_attrs(owner = "graph", flaky_attempts = 2))
tap_test_universe(name = "perf_universe", scope = ["//services/...", "//lib/..."], tags = ["perf-gate"])
```

**Impact aspect** — materialize a per-target source-impact manifest (the engine diffs two commits'
manifests for precise change-impact):

```sh
bazel build //... --aspects=@rules_tap//bazel:aspects.bzl%test_impact_aspect --output_groups=tap_impact
```

**Change-based test selection in CI** — the prebuilt CLI, no source or Rust toolchain needed:

```sh
bazel run @rules_tap//cli:tap -- affected --base "$CI_MERGE_REQUEST_DIFF_BASE_SHA" --tag perf-gate \
  | xargs bazel test --keep_going
```

## Surface

| Target | What |
|---|---|
| `@rules_tap//bazel:defs.bzl` | `test_impact_aspect`, `tap_test_attrs`, `tap_test_universe` (pure Starlark) |
| `@rules_tap//cli:tap` | the prebuilt `tap` CLI (`native_binary`, host-arch-selected) |
