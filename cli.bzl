"""Module extension: fetch the per-arch prebuilt `tap` CLI from THIS repo's GitHub release assets.

The private fastverk/tap repo's `publish-tap-cli` workflow builds `tap-<os>_<arch>.tar.gz` (each
containing the `tap` binary) and attaches it to the matching `tap-cli-v<ver>` release here. `//cli:tap`
selects the arch-matching binary — no engine source, no Rust toolchain, no recompile. Mirrors
rules_lang//lean:atlas.bzl ↔ aion/polyglot's publish_atlas_olean.

When the CLI is re-released, bump _BASE + the per-arch sha256 (the publish-tap-cli workflow opens
that bump PR automatically).
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

_CLI_BUILD = 'exports_files(["tap"])\n'

_BASE = "https://github.com/fastverk/rules_tap/releases/download/tap-cli-v0.0.2"

def _tap_cli_ext_impl(_ctx):
    http_archive(
        name = "tap_cli_linux_x86_64",
        url = _BASE + "/tap-linux_x86_64.tar.gz",
        sha256 = "3cf45c0b35f01e8728df64420e510f79fdf5c5c5c9dcdb2dd7e2a405ca1fb0ad",
        build_file_content = _CLI_BUILD,
    )
    http_archive(
        name = "tap_cli_darwin_arm64",
        url = _BASE + "/tap-darwin_arm64.tar.gz",
        sha256 = "287a3224a45c74a6c0174797b21e9c5dea20895cf30338c89b3f1cd004fe1c33",
        build_file_content = _CLI_BUILD,
    )

tap_cli = module_extension(implementation = _tap_cli_ext_impl)
