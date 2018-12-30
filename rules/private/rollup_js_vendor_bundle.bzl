def _impl(ctx):
    node_executable = ctx.attr.node_executable.files.to_list()[0]
    rollup_script = ctx.attr.rollup_script.files.to_list()[0]
    module_name = ctx.attr.module_name
    node_modules_path = rollup_script.path.split("/node_modules/")[0] + "/node_modules"
    exports = ctx.attr.exports

    dep_files = []
    for d in ctx.attr.deps:
        dep_files.extend(d.files.to_list())

    entrypoint_js_file = ctx.actions.declare_file("%s-entrypoint.js" % module_name)

    vendor_import_entries = []
    for export_name in exports:
        vendor_import_entries.append("import * as %s from '%s'" % (exports[export_name], export_name))

    vendor_entrypoint_content = \
        "\n".join(vendor_import_entries) + \
        "\n\n" + \
        "export default {\n" + \
        ",\n".join(exports.values()) + \
        "}\n"

    ctx.actions.write(
        output=entrypoint_js_file,
        content=vendor_entrypoint_content)

    dest_file = ctx.actions.declare_file(module_name + ".js")
    sourcemap_file = ctx.actions.declare_file(module_name + ".js.map")

    # transitive deps are not properly imported without the includePaths fix, detailed here:
    # https://github.com/rollup/rollup-plugin-node-resolve/issues/105#issuecomment-332640015

    rollup_config_content = """
const path = require('path');
import commonjs from 'rollup-plugin-commonjs';
import resolve from 'rollup-plugin-node-resolve';
import includePaths from 'rollup-plugin-includepaths';

export default {
  input: '%s',
  output: {
    file: '%s',
    format: 'iife',
    sourcemap: true,
    sourcemapFile: '%s',
    name: '%s',
    intro: 'const global = window'
  },
  plugins: [
    resolve({
      preferBuiltins: false,
    }),
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
    )

    rollup_config_file = ctx.actions.declare_file("%s-rollup-config.js" % module_name)
    ctx.actions.write(
        output=rollup_config_file,
        content=rollup_config_content)

    ctx.action(
        command="ln -s %s node_modules;%s %s -c %s" % (
            node_modules_path,
            node_executable.path,
            rollup_script.path,
            rollup_config_file.path,
        ),
        inputs=dep_files,
        outputs = [dest_file, sourcemap_file],
        progress_message = "running rollup js '%s'..." % module_name,
        tools = [
            node_executable,
            rollup_script,
            rollup_config_file,
            entrypoint_js_file,
        ] + ctx.attr.rollup_plugins.files.to_list() + dep_files
    )

    return [DefaultInfo(files=depset([dest_file]))]

rollup_js_vendor_bundle = rule(
    implementation = _impl,

    attrs = {
      "module_name": attr.string(mandatory=True),
      "exports": attr.string_dict(),
      "deps": attr.label_list(),

      "node_executable": attr.label(allow_files=True, mandatory=True),
      "rollup_script": attr.label(allow_files=True, mandatory=True),
      "rollup_plugins": attr.label(mandatory=True),
    }
)
