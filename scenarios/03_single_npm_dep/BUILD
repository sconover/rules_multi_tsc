load("@rules_multi_tsc//:def.bzl", "rollup_js_bundle2")
load("@rules_multi_tsc//:def.bzl", "rollup_js_source_bundle")

rollup_js_bundle2(
    name="bundle",
    module_name="lgen",
    entrypoint_js_content="const x = require('lgen/long-gen'); console.log(x.longGen())",
    tsc_dep="//03_single_npm_dep/long-gen:tsc",
    node_deps=[
      "@node_modules_archive//:long",
    ],

    node_executable="@node//:bin/node",
    rollup_script="@node_modules_archive//:node_modules/rollup/bin/rollup",
    rollup_plugins="@node_modules_archive//:rollup_plugins",
)

rollup_js_source_bundle(
    name="source_bundle",
    module_name="lgen_source",
    entrypoint_js_content="const x = require('lgen/long-gen'); console.log(x.longGen())",
    tsc_dep="//03_single_npm_dep/long-gen:tsc",
    globals={
      "long": "vendor._long"
    },

    node_executable="@node//:bin/node",
    rollup_script="@node_modules_archive//:node_modules/rollup/bin/rollup",
    rollup_plugins="@node_modules_archive//:rollup_plugins",
)
