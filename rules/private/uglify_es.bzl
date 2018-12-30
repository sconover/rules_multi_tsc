load(":rollup_js_result.bzl", "RollupJsResult")

def _impl(ctx):
    node_executable = ctx.attr.node_executable.files.to_list()[0]
    uglify_script = ctx.attr.uglify_script.files.to_list()[0]

    if RollupJsResult not in ctx.attr.rollup_dep:
        fail("uglify es error: rollup_js_dep must be specified and must be a rollup js target")
    rollup_js_result = ctx.attr.rollup_dep[RollupJsResult]

    base_js_name = rollup_js_result.js_file.basename.rsplit(".js", 1)[0]
    dest_file = ctx.actions.declare_file(base_js_name + ".min.js")
    sourcemap_file = ctx.actions.declare_file(base_js_name + ".min.js.map")

    ctx.action(
        command=" ".join([
            "%s %s --compress --mangle",
            "--output=%s",
            "--source-map \"content='%s'\"",
            "%s"
        ])  % (
            node_executable.path,
            uglify_script.path,
            dest_file.path,
            rollup_js_result.sourcemap_file.path,
            rollup_js_result.js_file.path
        ),
        inputs=[rollup_js_result.js_file, rollup_js_result.sourcemap_file],
        outputs = [dest_file, sourcemap_file],
        progress_message = "running uglify es '%s'..." % rollup_js_result.js_file.basename,
        tools = [
            node_executable,
            uglify_script,
        ]
    )

    return [DefaultInfo(files=depset([dest_file, sourcemap_file]))]

uglify_es = rule(
    implementation = _impl,

    attrs = {
      "node_executable": attr.label(allow_files=True, mandatory=True),
      "uglify_script": attr.label(allow_files=True, mandatory=True),

      "rollup_dep": attr.label(mandatory=True),
    }
)
