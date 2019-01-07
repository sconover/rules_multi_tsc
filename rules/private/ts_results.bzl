TsLibraryResult = provider(
    fields = [
        "ts_path",
        "tsc_out_dir",
        "ts_declaration_files",
    ]
)

CumulativeJsResult = provider(
    fields = [
        "ts_path_to_js_dir",
        "js_and_sourcemap_files",
    ]
)