"""Public Starlark API for tap.

Consumers load everything from here:

    load("@rules_tap//bazel:defs.bzl", "test_impact_aspect", "tap_test_universe", "tap_test_attrs")
"""

load("//bazel:aspects.bzl", _test_impact_aspect = "test_impact_aspect")
load(
    "//bazel:rules.bzl",
    _tap_test_attrs = "tap_test_attrs",
    _tap_test_universe = "tap_test_universe",
)

test_impact_aspect = _test_impact_aspect
tap_test_universe = _tap_test_universe
tap_test_attrs = _tap_test_attrs
