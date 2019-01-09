load(":tsc.bzl", "CumulativeJsResult")
load(":rollup_js_result.bzl", "RollupJsResult")

def _impl(ctx):
    node_executable = ctx.attr.node_executable.files.to_list()[0]
    rollup_script = ctx.attr.rollup_script.files.to_list()[0]
    node_modules_path = rollup_script.path.split("/node_modules/")[0] + "/node_modules"
    entrypoint_js_content = ctx.attr.entrypoint_js_content # TODO: must specify if source or all type
    module_name = ctx.attr.module_name
    tsc_dep = ctx.attr.tsc_dep
    module_globals = ctx.attr.globals

    entrypoint_js_file = ctx.actions.declare_file("%s-entrypoint.js" % module_name)

    if CumulativeJsResult not in tsc_dep:
        fail("tsc_dep must be a tsc target")

    ctx.actions.write(
        output=entrypoint_js_file,
        content=entrypoint_js_content)

    cumulative_js_result = tsc_dep[CumulativeJsResult]
    inputs = cumulative_js_result.js_and_sourcemap_files
    ts_path_to_js_dir = cumulative_js_result.ts_path_to_js_dir
    if ts_path_to_js_dir == None:
        ts_path_to_js_dir = {}

    alias_entries = []
    for ts_path in ts_path_to_js_dir:
        alias_entries.append("'%s' : path.resolve(process.cwd(), './%s')" % (ts_path, ts_path_to_js_dir[ts_path]))
    alias_str = "{\n" + ",\n".join(alias_entries) + "}\n"

    dest_file = ctx.actions.declare_file(module_name + ".js")
    sourcemap_file = ctx.actions.declare_file(module_name + ".js.map")

    globals_config = ""
    externals_config = ""
    if (len(module_globals)>0):
        externals_entries = []
        for k in module_globals.keys():
            externals_entries.append("'%s'" % k)
        externals_config = """
            external: [
                %s
            ],
            """ % ",\n".join(externals_entries)

        globals_entries = []
        for global_name in module_globals:
            globals_entries.append("'%s': '%s'" % (global_name, module_globals[global_name]))
        globals_config = ", globals: {\n" + ",\n".join(globals_entries) + "}\n"


    rollup_config_content = """
const path = require('path');
import alias from 'rollup-plugin-alias';
import commonjs from 'rollup-plugin-commonjs';
import sourcemaps from 'rollup-plugin-sourcemaps';

export default {
  input: '%s',
  output: {
    file: '%s',
    format: 'iife',
    sourcemap: true,
    sourcemapFile: '%s',
    name: '%s',
    intro: 'const global = window'
    %s
  },
  %s
  plugins: [
    sourcemaps(),
    alias(
      %s
    ),
    commonjs()
  ],
  onwarn(warning) {
    if (['UNRESOLVED_IMPORT', 'MISSING_GLOBAL_NAME'].indexOf(warning.code)>=0) {
      console.error(warning.message)
      process.exit(1)
    } else {
      console.warn(warning.message)
    }
  }

};
    """ % (
      entrypoint_js_file.path,
      dest_file.path,
      sourcemap_file.path,
      module_name,
      globals_config,
      externals_config,
      alias_str
    )

    rollup_config_file = ctx.actions.declare_file("%s-rollup-config.js" % module_name)
    ctx.actions.write(
        output=rollup_config_file,
        content=rollup_config_content)

    ctx.action(
        command="ln -s %s node_modules;env NODE_PATH=node_modules %s %s -c %s" % (
            node_modules_path,
            node_executable.path,
            rollup_script.path,
            rollup_config_file.path,
        ),
        inputs=inputs,
        outputs = [dest_file, sourcemap_file],
        progress_message = "running rollup js '%s'..." % module_name,
        tools = [
            node_executable,
            rollup_script,
            rollup_config_file,
            entrypoint_js_file,
        ] + ctx.attr.rollup_plugins.files.to_list()
    )

    return [
        DefaultInfo(files=depset([dest_file, sourcemap_file])),
        RollupJsResult(js_file=dest_file, sourcemap_file=sourcemap_file),
    ]

rollup_js_source_bundle = rule(
    implementation = _impl,

    attrs = {
      "entrypoint_js_content": attr.string(),
      "module_name": attr.string(mandatory=True),

      "tsc_dep": attr.label(),
      "globals": attr.string_dict(),

      "node_executable": attr.label(allow_files=True, mandatory=True),
      "rollup_script": attr.label(allow_files=True, mandatory=True),
      "rollup_plugins": attr.label(mandatory=True),
    }
)
