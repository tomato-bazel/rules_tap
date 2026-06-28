"""test_impact_aspect — emits a per-target impact manifest as it rides the dep graph.

Run it over the whole graph to materialize an owned, cacheable target→inputs map
(the spine for change-impact, flake attribution, and runtime-balanced sharding):

    bazel build //... \\
      --aspects=@rules_tap//bazel:aspects.bzl%test_impact_aspect \\
      --output_groups=tap_impact

Each target gets `<name>.tap-impact.json` with its transitive source set + tags +
owner. The Rust engine diffs two commits' manifests to compute the impacted test
set — precisely, including BUILD/macro/toolchain edges that `git diff → rdeps`
misses. (v0 emits the manifest; content-hashing lands with the engine.)
"""

TapImpactInfo = provider(
    doc = "Transitive source set + metadata for one target.",
    fields = {"srcs": "depset of source File objects", "manifest": "the per-target JSON File"},
)

def _owner_of(ctx):
    for t in getattr(ctx.rule.attr, "tags", []):
        if t.startswith("tap-owner="):
            return t[len("tap-owner="):]
    return ""

def _impl(target, ctx):
    direct = []
    for a in ["srcs", "hdrs", "data"]:
        direct += getattr(ctx.rule.files, a, [])

    transitive = [
        d[TapImpactInfo].srcs
        for d in getattr(ctx.rule.attr, "deps", [])
        if TapImpactInfo in d
    ]
    srcs = depset(direct = direct, transitive = transitive)

    manifest = ctx.actions.declare_file("{}.tap-impact.json".format(target.label.name))
    ctx.actions.write(
        output = manifest,
        content = json.encode(struct(
            label = str(target.label),
            kind = ctx.rule.kind,
            owner = _owner_of(ctx),
            tags = getattr(ctx.rule.attr, "tags", []),
            is_test = ctx.rule.kind.endswith("_test"),
            srcs = [f.path for f in srcs.to_list()],
        )),
    )

    return [
        TapImpactInfo(srcs = srcs, manifest = manifest),
        OutputGroupInfo(tap_impact = depset([manifest], transitive = [
            d[OutputGroupInfo].tap_impact
            for d in getattr(ctx.rule.attr, "deps", [])
            if OutputGroupInfo in d and hasattr(d[OutputGroupInfo], "tap_impact")
        ])),
    ]

test_impact_aspect = aspect(
    implementation = _impl,
    attr_aspects = ["deps"],
    doc = "Emits a transitive-source impact manifest per target into the `tap_impact` output group.",
)
