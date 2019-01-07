package(default_visibility = ["//:__subpackages__"])

load("@rules_multi_tsc//:def.bzl", "tsc")

tsc(
    name="tsc",
    ts_path="shape",
    srcs=["square.ts"],
    deps=[
        "//06_typings/typings:typings",
    ],

    node_executable="@node//:bin/node",
    tsc_script="@node_modules_archive//:node_modules/typescript/lib/tsc.js",
    tsconfig_json="//:tsconfig.json",
)
