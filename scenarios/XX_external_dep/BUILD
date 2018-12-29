package(default_visibility = ["//:__subpackages__"])

load("@rules_multi_tsc//:def.bzl", "rollup_js_source_bundle")
load("@rules_multi_tsc//:def.bzl", "rollup_js_vendor_bundle")

rollup_js_vendor_bundle(
    name="vendor_bundle",
    module_name="vendor",
    exports={
      "long": "_long",
      "bson": "_bson"
    },
    deps=[
      "@node_modules_archive//:long",
      "@node_modules_archive//:bson",
    ],

    node_executable="@node//:bin/node",
    rollup_script="@node_modules_archive//:node_modules/rollup/bin/rollup",
    rollup_plugins="@node_modules_archive//:rollup_plugins",
)

rollup_js_source_bundle(
    name="source_bundle",
    module_name="source",
    entrypoint_js_content="const x = require('lgen/long-gen'); console.log(x.longGen())",
    tsc_dep="//XX_external_dep/print-timestamp:tsc",
    globals={
      "long": "vendor._long",
      "bson": "vendor._bson"
    },

    node_executable="@node//:bin/node",
    rollup_script="@node_modules_archive//:node_modules/rollup/bin/rollup",
    rollup_plugins="@node_modules_archive//:rollup_plugins",
)
