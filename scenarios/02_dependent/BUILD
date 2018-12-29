package(default_visibility = ["//:__subpackages__"])

load("@rules_multi_tsc//:def.bzl", "rollup_js_source_bundle")

# Note that because we only make use of hexagonal prism at the entrypoint,
# no triangle-related code is included in the bundle.

rollup_js_source_bundle(
    name="hexagonal_prism_bundle",
    entrypoint_js_content="const x = require('prism/hexagonal-prism'); console.log(new x.HexagonalPrism(7, 20))",
    module_name="hexagonalPrism",
    tsc_dep="//02_dependent/prism:tsc",

    node_executable="@node//:bin/node",
    rollup_script="@node_modules_archive//:node_modules/rollup/bin/rollup",
    rollup_plugins="@node_modules_archive//:rollup_plugins",
)
