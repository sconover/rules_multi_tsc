GenerateTsconfigInput = provider(
    fields = [
        "tsconfig_template_json_file",
        "srcs",
        "out_dir",
        "package_relative_path",
        "paths_mapping",
    ]
)

TscResult = provider(
    fields = [
        "import_path",
        "tsc_out_dir",
        "ts_declaration_files",
    ]
)

CumulativeJsResult = provider(
    fields = [
        "import_path_to_js_dir",
        "node_modules",
        "js_and_sourcemap_files",
    ]
)

def _impl(ctx):
    generate_tsconfig_json_js_script = ctx.attr._generate_tsconfig_json_js.files.to_list()[0]
    source_root_dir = ctx.label.package # might want to make this overridable in the future
    tsc_script = ctx.attr.tsc_script.files.to_list()[0]
    node_modules_path = tsc_script.path.split("/node_modules/")[0] + "/node_modules"
    tsconfig_json = ctx.attr.tsconfig_json.files.to_list()[0]
    node_executable = ctx.attr.node_executable.files.to_list()[0]

    import_path = ctx.attr.import_path
    if len(import_path) == 0:
        import_path = ctx.label.package.split("/")[-1]

    tsc_out_dir = None # TODO: handling for when this is never set (fail - must be comiling at least one thing)

    if len(ctx.attr.srcs) == 0:
        fail("tsc rule error: srcs must have at least one item.")

    tsc_outputs = []
    ts_declaration_outputs = []
    js_and_sourcemap_outputs = []

    src_file_paths = []
    src_files = []
    for src in ctx.attr.srcs:
        f = src.files.to_list()[0]
        src_file_paths.append(f.path.replace(source_root_dir + "/", "", 1))
        src_files.append(f)

        basename_without_extension = f.basename.rsplit("." + f.extension, 1)[0]
        declaration_out_file = ctx.actions.declare_file("%s.d.ts" % basename_without_extension)
        js_out_file = ctx.actions.declare_file("%s.js" % basename_without_extension)
        sourcemap_out_file = ctx.actions.declare_file("%s.js.map" % basename_without_extension)

        bazel_out_root_dir = declaration_out_file.dirname.split(ctx.label.package)[0]
        tsc_out_dir = bazel_out_root_dir + ctx.label.package

        ts_declaration_outputs.append(declaration_out_file)
        js_and_sourcemap_outputs.append(js_out_file)
        js_and_sourcemap_outputs.append(sourcemap_out_file)

        tsc_outputs.append(declaration_out_file)
        tsc_outputs.append(js_out_file)
        tsc_outputs.append(sourcemap_out_file)

    cumulative_js_result = CumulativeJsResult(
        import_path_to_js_dir = {},
        node_modules = {},
        js_and_sourcemap_files = []
    )
    deps_files = []
    paths_mapping = {}
    dependency_ts_declaration_files = []
    node_modules = {}
    for dep in ctx.attr.deps:
        for f in dep.files.to_list():
            deps_files.append(f)
            if f.basename == "package.json" and "node_modules" in f.path.split("/"):
                node_module_name = f.dirname.split("/")[-1]
                node_modules[node_module_name] = f.dirname

        if TscResult in dep:
            r = dep[TscResult]
            # TODO: throw error if path exists
            paths_mapping[r.import_path + "/*"] = [r.tsc_out_dir + "/*"]
            dependency_ts_declaration_files.extend(r.ts_declaration_files.to_list())

        if CumulativeJsResult in dep:
            r = dep[CumulativeJsResult]

            if r.import_path_to_js_dir != None:
                for p in r.import_path_to_js_dir:
                    # TODO: fail if import path is duplicate
                    cumulative_js_result.import_path_to_js_dir[p] = r.import_path_to_js_dir[p]

            if r.node_modules != None:
                cumulative_js_result.node_modules.update(r.node_modules)

            cumulative_js_result.js_and_sourcemap_files.extend(r.js_and_sourcemap_files)

    script_input_data_file = ctx.actions.declare_file("generate_tsconfig_input.json")
    ctx.actions.write(
        output=script_input_data_file,
        content=GenerateTsconfigInput(
            tsconfig_template_json_file=tsconfig_json.path,
            srcs=src_file_paths,
            out_dir=tsc_out_dir,
            package_relative_path=ctx.label.package,
            paths_mapping=paths_mapping,
        ).to_json())

    generated_tsconfig_json_file = ctx.actions.declare_file("tsconfig.gen-initial.json")

    ts_inputs = src_files + dependency_ts_declaration_files

    ctx.action(
        command="%s %s %s $(pwd) > %s" % ( # TODO: replace subshell pwd
            node_executable.path,
            generate_tsconfig_json_js_script.path,
            script_input_data_file.path,
            generated_tsconfig_json_file.path
        ),
        inputs=ts_inputs,
        outputs = [generated_tsconfig_json_file],
        progress_message = "generating tsconfig for '%s'..." % import_path,
        tools = [
            node_executable,
            generate_tsconfig_json_js_script,
            tsconfig_json,
            script_input_data_file,
        ]
    )

    # You would think that with moduleResolution=node in tsconfig, that something like NODE_PATH
    # would be scanned my tsc. That's not the case, per
    # https://www.typescriptlang.org/docs/handbook/module-resolution.html
    # Instead it insists on this parent-directory-walking strategy. Sigh.
    # also relevant, and disapointing https://github.com/Microsoft/TypeScript/issues/8760
    #
    # So the strategy below is to just symlink to the node_modules sitting under external/ ,
    # in a tsc-friendly location.

    ctx.action(
        command=" && ".join([
            "cp %s tsconfig.for-use.json" % generated_tsconfig_json_file.path,
            "ln -sf %s node_modules" % node_modules_path,
            "%s %s -p tsconfig.for-use.json" % ( #TODO: flag to enable trace resolution...or rather, optional rule param for flags
                node_executable.path,
                tsc_script.path
            ),
        ]),
        inputs=[generated_tsconfig_json_file] + ts_inputs,
        outputs = tsc_outputs,
        progress_message = "running tsc for '%s'..." % import_path,
        tools = [
            node_executable,
            tsc_script,
        ] + deps_files
    )

    # The "additional" file is here so the action cache invalidates
    # when anything that is returned by this rule changes, or is important
    # re: the tsc run.
    additional_file = ctx.actions.declare_file("additional_output_for_hashing")
    ctx.actions.write(
        output=additional_file,
        content="\n".join([
            import_path,
            tsc_out_dir,
            node_executable.path,
            tsc_script.path,
        ]))

    import_path_to_js_dir = cumulative_js_result.import_path_to_js_dir

    if import_path_to_js_dir == None:
        import_path_to_js_dir = {}
    import_path_to_js_dir[import_path] = tsc_out_dir # TODO: fail if key exists

    new_mode_module_set = cumulative_js_result.node_modules
    new_mode_module_set.update(node_modules)

    return [
        DefaultInfo(
            files=depset(
                [additional_file, generated_tsconfig_json_file] +
                ts_declaration_outputs +
                dependency_ts_declaration_files
            ),
        ),
        TscResult(
            import_path=import_path,
            tsc_out_dir=tsc_out_dir,
            ts_declaration_files=depset(ts_declaration_outputs), # note: dependency .d.ts's not propagated
        ),
        CumulativeJsResult(
            import_path_to_js_dir=import_path_to_js_dir,
            node_modules=new_mode_module_set,
            js_and_sourcemap_files=cumulative_js_result.js_and_sourcemap_files + js_and_sourcemap_outputs,
        )
    ]

tsc = rule(
    implementation = _impl,

    attrs = {
      "import_path": attr.string(),
      "srcs": attr.label_list(allow_files=True, mandatory=True),
      "deps": attr.label_list(default=[]),

      "node_executable": attr.label(allow_files=True, mandatory=True),
      "tsc_script": attr.label(allow_files=True, mandatory=True),
      "tsconfig_json": attr.label(allow_files=True, mandatory=True),

      "_generate_tsconfig_json_js": attr.label(default=Label("//private:generate_tsconfig_json.js"), allow_files=True, single_file=True),
    }
)