package(default_visibility = ["//:__subpackages__"])

load("@rules_multi_tsc//:def.bzl", "tsc")

# Of note:
# The 'basics' module is not automatically exposed to prism.
# Without the explicit dependency below, Point2d will not
# be seen by tsc, so compilation will fail.

tsc(
    name="tsc",
    import_path="prism",
    srcs=glob(["*.ts"]),
    deps=[
      "//02_dependent/basics:tsc",
      "//02_dependent/polygon:tsc"
    ],

    node_executable="@node//:bin/node",
    tsc_script="@node_modules_archive//:node_modules/typescript/lib/tsc.js",
    tsconfig_json="//:tsconfig.json",
)
