package(default_visibility = ["//:__subpackages__"])

load("@rules_multi_tsc//:def.bzl", "tsc")

tsc(
    name="tsc",
    import_path="lgen",
    srcs=glob(["*.ts"]),
    deps=[
      "@node_modules_archive//:default_typings",
      "@node_modules_archive//:long",
    ],

    node_executable="@node//:bin/node",
    tsc_script="@node_modules_archive//:node_modules/typescript/lib/tsc.js",
    tsconfig_json="//:tsconfig.json",
)
