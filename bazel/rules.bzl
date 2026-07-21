"""tap test-authoring helpers.

`tap_test_attrs` — splat uniform flake/shard/owner metadata into any test rule:

    load("@rules_tap//bazel:defs.bzl", "tap_test_attrs")
    ts_test(name = "test_node", srcs = [...], **tap_test_attrs(owner = "graph", flaky_attempts = 2))

`tap_test_universe` — the hermetic, cacheable list of every test the lane may run
(genquery can't take //... — the seed list is the finite universe). Replaces the
hand-rolled //tools/bazel/tests pattern; the engine regenerates + drift-checks it.
"""

def tap_test_attrs(owner, flaky_attempts = 0, shard_count = 1, extra_tags = []):
    """Returns a dict to splat into a test rule, tagging it for tap.

    Args:
      owner: team that owns the test; emitted as a `tap-owner=<owner>` tag.
        Falsy values add no owner tag.
      flaky_attempts: if > 0, marks the test `flaky`. Note this sets the
        boolean attr only — Bazel's own `--flaky_test_attempts` decides the
        retry count, so the number here is a threshold, not a count.
      shard_count: passed through as `shard_count` only when > 1, since 1 is
        already the default and emitting it would be noise.
      extra_tags: additional tags merged ahead of the generated ones.

    Returns:
      A dict of test-rule attributes to splat with `**`. Always carries
      `tags`; carries `shard_count` and `flaky` only when they differ from
      the defaults.
    """
    tags = ["tap"] + extra_tags
    if owner:
        tags.append("tap-owner=" + owner)
    attrs = {"tags": tags}
    if shard_count > 1:
        attrs["shard_count"] = shard_count
    if flaky_attempts > 0:
        attrs["flaky"] = True
    return attrs

def tap_test_universe(name, scope, tags = None, **kwargs):
    """A genquery over `scope` selecting test targets (optionally tag-filtered).

    Args:
      name: target name.
      scope: explicit label list (genquery requires a finite scope, no //...).
      tags: optional list of tags to AND-filter the universe.
      **kwargs: forwarded verbatim to the underlying `native.genquery`
        (`visibility`, `testonly`, and so on).
    """
    expr = "kind(test, set(%s))" % " ".join(scope)
    if tags:
        for t in tags:
            expr = "attr(tags, '\\\\b%s\\\\b', %s)" % (t, expr)
    native.genquery(
        name = name,
        expression = expr,
        scope = scope,
        **kwargs
    )
