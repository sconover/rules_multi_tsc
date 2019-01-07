load(":ts_results.bzl", "TsLibraryResult", "CumulativeJsResult")

def _impl(ctx):
    ts_path = ctx.attr.ts_path
    tsc_out_dir = "/tmp"

    src_files = []
    for src in ctx.attr.srcs:
        for src_f in src.files.to_list():
            src_files.append(src_f)

    return [
        DefaultInfo(
            files=depset(src_files),
        ),
        TsLibraryResult(
            ts_path=ts_path,
            tsc_out_dir=ctx.label.package,
            ts_declaration_files=depset(src_files),
        ),
        CumulativeJsResult(
            ts_path_to_js_dir={},
            js_and_sourcemap_files=[],
        )
    ]

typings = rule(
    implementation = _impl,

    attrs = {
      "ts_path": attr.string(),
      "srcs": attr.label_list(allow_files=True, mandatory=True),
    }
)