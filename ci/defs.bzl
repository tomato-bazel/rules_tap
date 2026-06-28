"""tap_ci_feature — a `fastverk_project` feature bundle for tap's change-based
affected-test selection.

`tap` sits UNDER `fastverk_project` (rules_ci) in the fastverk layering. Rather than
rules_ci taking a hard `bazel_dep` on rules_tap — which would invert that layering (the
generic CI layer depending on one specific test product, and every consumer pulling tap
whether they use it or not) — `rules_tap` EXPORTS this helper. It returns the
catalog-agnostic feature-bundle shape `fastverk_project(features = {...})` consumes
(`{"jobs": {...}, "variables": {...}}`), so the affected-test lane composes into a
generated pipeline with ZERO coupling between the two modules:

    load("@rules_tap//ci:defs.bzl", "tap_ci_feature")

    fastverk_project(
        name = "project",
        repo = "aion/db",
        features = {"tap": tap_ci_feature()},
    )

The generated job supersedes the legacy `scripts/ci/affected-test-targets.sh`: it runs
the prebuilt `tap` CLI — fetched anonymously from the public rules_tap release, no GitHub
auth — to print the affected `bazel test` labels, then runs exactly those
(`bazel run @rules_tap//cli:tap -- affected … | xargs -r bazel test`), matching the
invocation in this repo's README and the legacy bash. `xargs -r` skips `bazel test` on an
empty diff (no affected tests) rather than invoking it with no targets, and `set -o
pipefail` makes a failure in the affected-selection step fail the job instead of being
masked by xargs' success.

The CLI is CI-env-aware (since tap-cli-v0.0.2): with no `--base` it resolves the diff base
from the pipeline env (CI_MERGE_REQUEST_DIFF_BASE_SHA, GITHUB_BASE_REF, then the
origin/main merge-base) AND forces the full tag-filtered universe on a tag pipeline, a
default-branch build, or the BAZEL_TEST_ALL override. So this ONE job is correct in every
pipeline context — affected on MRs, full on main/tags — with no `rules:` gymnastics. That's
why `diff_base` defaults to "" (omit `--base`, let the CLI resolve); pass an explicit value
only for a non-standard CI where the env vars differ.
"""

def tap_ci_feature(
        job_name = "test:affected",
        stage = "test",
        diff_base = "",
        tag = None,
        cli_target = "@rules_tap//cli:tap",
        bazel = "bazel",
        keep_going = True,
        extra_test_flags = [],
        job_extra = {},
        variables = {}):
    """Return a `fastverk_project` feature bundle running tap's affected-test lane.

    Args:
      job_name: the generated GitLab CI job name (default "test:affected").
      stage: the pipeline stage the job runs in (default "test").
      diff_base: shell expression for an explicit base ref to diff against. Default "" =
        omit `--base` and let the env-aware CLI resolve it (CI_MERGE_REQUEST_DIFF_BASE_SHA
        / GITHUB_BASE_REF / origin/main merge-base) and force full runs on main/tags — the
        correct, normal case. Set a value only for a non-standard CI.
      tag: restrict to tests carrying this Bazel tag (e.g. "perf-gate"); None = all tests.
      cli_target: the prebuilt tap CLI label (default "@rules_tap//cli:tap").
      bazel: the bazel launcher invoked in the job (default "bazel").
      keep_going: pass `--keep_going` to `bazel test` so one failing target doesn't mask
        the rest (default True).
      extra_test_flags: additional flags appended to the `bazel test` invocation.
      job_extra: arbitrary extra GitLab CI job keys merged into the generated job
        (`rules`, `needs`, `image`, `tags`, `interruptible`, …) — the escape hatch for
        repo-specific pipeline wiring the helper doesn't model.
      variables: extra CI/CD variables contributed by this feature.

    Returns:
      A feature-bundle dict `{"jobs": {<job_name>: {...}}, "variables": {...}}` for
      `fastverk_project(features = {"<name>": tap_ci_feature(...)})`.
    """
    base_arg = (' --base "%s"' % diff_base) if diff_base else ""
    tag_arg = (' --tag "%s"' % tag) if tag else ""
    test_flags = (" --keep_going" if keep_going else "") + "".join([" " + f for f in extra_test_flags])

    script = [
        # Fail the job if the affected-selection step (left of the pipe) errors — GitLab
        # CI doesn't enable pipefail by default, so xargs' success would otherwise mask it.
        "set -o pipefail",
        # Run the prebuilt tap CLI (fetched anonymously) to print the diff-affected test
        # labels, then run exactly those. `-r` skips `bazel test` when the diff affects no
        # tests (empty stdin) rather than invoking it with no targets.
        "%s run %s -- affected%s%s | xargs -r %s test%s" % (bazel, cli_target, base_arg, tag_arg, bazel, test_flags),
    ]

    job = {"stage": stage, "script": script}
    for k, v in job_extra.items():
        job[k] = v

    return {
        "jobs": {job_name: job},
        "variables": dict(variables),
    }
