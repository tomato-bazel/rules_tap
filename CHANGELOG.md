# Changelog

All notable changes to rules_tap. The format is loosely
[Keep a Changelog](https://keepachangelog.com/) — version headers
mirror the published bazel-registry entries.

## 0.0.1

- The public Bazel surface for tap, extracted from the (now private) `fastverk/tap`:
  - `//bazel:defs.bzl` — `test_impact_aspect` (per-target source-impact manifest aspect),
    `tap_test_attrs` (owner/flake/shard tagging), `tap_test_universe` (cacheable genquery universe).
    Pure Starlark, no dependency on the private engine.
  - `//cli:tap` — the prebuilt, per-arch `tap` CLI, fetched from this repo's GitHub release assets
    (`tap-cli-v*`) by `//:cli.bzl` and exposed as a host-arch-selected `native_binary`. Built +
    uploaded by the private `fastverk/tap` repo's `publish-tap-cli` workflow (mirrors rules_lang's
    atlas oleans).
