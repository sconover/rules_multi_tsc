load("@rules_multi_tsc//:def.bzl", "rollup_js_source_bundle")
load("@rules_multi_tsc//:def.bzl", "rollup_js_vendor_bundle")

rollup_js_vendor_bundle(
    name="vendor_bundle",
    module_name="lgen_vendor",
    exports={
      "long": "_long"
    },
    deps=[
      "@node_modules_archive//:long"
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
      "long": "lgen_vendor._long"
    },

    node_executable="@node//:bin/node",
    rollup_script="@node_modules_archive//:node_modules/rollup/bin/rollup",
    rollup_plugins="@node_modules_archive//:rollup_plugins",
)
