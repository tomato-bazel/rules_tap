# Changelog

All notable changes to rules_tap. The format is loosely
[Keep a Changelog](https://keepachangelog.com/) — version headers
mirror the published bazel-registry entries.

## 0.0.2

- `//ci:defs.bzl` — `tap_ci_feature()`, a `fastverk_project` (rules_ci) feature-bundle helper
  that adds tap's change-based affected-test lane to a generated CI pipeline:
  `fastverk_project(features = {"tap": tap_ci_feature()})`. Pure Starlark (returns a
  `{"jobs", "variables"}` dict) — rules_ci stays decoupled (no `bazel_dep` on rules_tap); the
  generic `features` mechanism composes the lane. The job runs the prebuilt `//cli:tap`
  (fetched anonymously) to emit the diff-affected `bazel test` labels and runs exactly those
  (`bazel run @rules_tap//cli:tap -- affected … | xargs -r bazel test`), superseding the legacy
  `scripts/ci/affected-test-targets.sh`. No change to the rules or the prebuilt CLI (still
  `tap-cli-v0.0.1`).

## 0.0.1

- The public Bazel surface for tap, extracted from the (now private) `fastverk/tap`:
  - `//bazel:defs.bzl` — `test_impact_aspect` (per-target source-impact manifest aspect),
    `tap_test_attrs` (owner/flake/shard tagging), `tap_test_universe` (cacheable genquery universe).
    Pure Starlark, no dependency on the private engine.
  - `//cli:tap` — the prebuilt, per-arch `tap` CLI, fetched from this repo's GitHub release assets
    (`tap-cli-v*`) by `//:cli.bzl` and exposed as a host-arch-selected `native_binary`. Built +
    uploaded by the private `fastverk/tap` repo's `publish-tap-cli` workflow (mirrors rules_lang's
    atlas oleans).
