package(default_visibility = ["//:__subpackages__"])

load("@rules_multi_tsc//:def.bzl", "rollup_js_bundle")

# Note that because we only make use of hexagonal prism at the entrypoint,
# no triangle-related code is included in the bundle.

rollup_js_bundle(
    name="bundle_all",
    entrypoint_js_content="const x = require('ptstamp/print-timestamp'); x.printTimestamp()",
    module_name="ptstampAll",
    root_tsc_dep="//03_external_dep/print-timestamp:tsc",
    node_executable="@node//:bin/node",
    rollup_script="@node_modules_archive//:node_modules/rollup/bin/rollup",
    rollup_plugins="@node_modules_archive//:rollup_plugins",
)

vendorized_libraries = {
  "long": "_long",
  "buffer": "_buffer",
  "bson": "_bson",
}

rollup_js_bundle(
    name="bundle_vendor",
    module_name="ptstampVendor",
    provides_node_libraries=vendorized_libraries,
    deps=[
      "@node_modules_archive//:long",
      "@node_modules_archive//:bson",
      "@node_modules_archive//:buffer",
    ],
    node_executable="@node//:bin/node",
    rollup_script="@node_modules_archive//:node_modules/rollup/bin/rollup",
    rollup_plugins="@node_modules_archive//:rollup_plugins",
)

rollup_js_bundle(
    name="bundle_source",
    module_name="ptstampSource",
    entrypoint_js_content="const x = require('ptstamp/print-timestamp'); x.printTimestamp()",
    uses_node_libraries=vendorized_libraries,
    library_provider_module_name="ptstampVendor",
    root_tsc_dep="//03_external_dep/print-timestamp:tsc",
    node_executable="@node//:bin/node",
    rollup_script="@node_modules_archive//:node_modules/rollup/bin/rollup",
    rollup_plugins="@node_modules_archive//:rollup_plugins",
)
