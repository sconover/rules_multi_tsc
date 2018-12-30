package(default_visibility = ["//:__subpackages__"])

load("@rules_multi_tsc//:def.bzl", "tsc")
load("@rules_multi_tsc//:def.bzl", "rollup_js_source_bundle")

genrule(
    name = "gen_ts",
    srcs = [],
    outs = ["foo.ts"],
    cmd = "echo 'export function doprint(): void { console.log(\"hello foo\") }' > \"$@\"",
)

tsc(
    name="tsc",
    ts_path="compiletsout",
    srcs=[":gen_ts"],

    node_executable="@node//:bin/node",
    tsc_script="@node_modules_archive//:node_modules/typescript/lib/tsc.js",
    tsconfig_json="//:tsconfig.json",
)

rollup_js_source_bundle(
    name="bundle",
    entrypoint_js_content="const x = require('compiletsout/foo'); x.doprint()",
    module_name="someModule",
    tsc_dep=":tsc",

    node_executable="@node//:bin/node",
    rollup_script="@node_modules_archive//:node_modules/rollup/bin/rollup",
    rollup_plugins="@node_modules_archive//:rollup_plugins",
)
