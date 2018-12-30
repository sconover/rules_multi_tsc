package(default_visibility = ["//:__subpackages__"])

load("@rules_multi_tsc//:def.bzl", "tsc")

tsc(
    name="tsc",
    ts_path="ptstamp",
    srcs=glob(["*.ts"]),
    deps=[
      "@node_modules_archive//:default_typings",
      "//04_external_deps/long-gen:tsc",
    ],

    node_executable="@node//:bin/node",
    tsc_script="@node_modules_archive//:node_modules/typescript/lib/tsc.js",
    tsconfig_json="//:tsconfig.json",
)
