load(":tsc.bzl", "CumulativeJsResult")

def _impl(ctx):
    node_executable = ctx.attr.node_executable.files.to_list()[0]
    rollup_script = ctx.attr.rollup_script.files.to_list()[0]
    entrypoint_js_content = ctx.attr.entrypoint_js_content # TODO: must specify if source or all type
    module_name = ctx.attr.module_name
    vendor_module_name = ctx.attr.vendor_module_name # TODO: must specify if source type
    node_modules_path = rollup_script.path.split("/node_modules/")[0] + "/node_modules"
    root_tsc_dep = ctx.attr.root_tsc_dep
    bundle_type = ctx.attr.bundle_type

    if CumulativeJsResult not in root_tsc_dep:
        fail("root_tsc_dep must be a tsc target")
    all_js = root_tsc_dep[CumulativeJsResult]

    vendor_js_import_statements = []
    vendor_js_exports = []
    source_js_vendored_externals = []
    source_js_vendored_globals = []
    for node_module_name in all_js.node_modules:
        vendor_js_import_statements.append("import * as _%s from '%s';" % (node_module_name, node_module_name))
        vendor_js_exports.append("  _%s" % node_module_name)
        source_js_vendored_externals.append("  '%s'" % node_module_name)
        source_js_vendored_globals.append("  '%s' : '%s._%s'" % (node_module_name, vendor_module_name, node_module_name))

    vendor_js_entrypoint_content = """
%s

export default {
%s
};
    """ % ("\n".join(vendor_js_import_statements), ",\n".join(vendor_js_exports))

    rollup_app_bundle_extra_config_content_for_vendoring = """
  ,
  external: [
    %s
  ],
  globals: {
    %s
  }
    """ % (",\n".join(source_js_vendored_externals), ",\n".join(source_js_vendored_globals))

    extra_config_content = ""
    if bundle_type == "source_only":
        extra_config_content = rollup_app_bundle_extra_config_content_for_vendoring

    import_path_to_js_dir = all_js.import_path_to_js_dir
    if import_path_to_js_dir == None:
        import_path_to_js_dir = {}

    alias_entries = []
    for import_path in import_path_to_js_dir:
        alias_entries.append("'%s' : path.resolve(process.cwd(), './%s')" % (import_path, import_path_to_js_dir[import_path]))
    alias_str = "{\n" + ",\n".join(alias_entries) + "}\n"

    entrypoint_js_file = ctx.actions.declare_file("%s-entrypoint.js" % module_name)
    if bundle_type == "vendor_only":
      ctx.actions.write(
          output=entrypoint_js_file,
          content=vendor_js_entrypoint_content)
    else:
      ctx.actions.write(
          output=entrypoint_js_file,
          content=entrypoint_js_content)

    dest_file = ctx.actions.declare_file(module_name + ".js")
    sourcemap_file = ctx.actions.declare_file(module_name + ".js.map")

    rollup_config_content = """
const path = require('path');
import commonjs from 'rollup-plugin-commonjs';
import alias from 'rollup-plugin-alias';
import resolve from 'rollup-plugin-node-resolve';

export default {
  input: '%s',
  output: {
    file: '%s',
    format: 'iife',
    sourcemap: true,
    sourcemapFile: '%s',
    name: '%s'
  },
  plugins: [
    commonjs(),
    alias(
      %s
    ),
    resolve({
      jsnext: true,
      browser: true,
      module: true,
      main: true,

      customResolveOptions: {
        moduleDirectory: '%s'
      },
    })
  ]
  %s
};
    """ % (
      entrypoint_js_file.path,
      dest_file.path,
      sourcemap_file.path,
      module_name,
      alias_str,
      node_modules_path,
      extra_config_content,
    )

    rollup_config_file = ctx.actions.declare_file("%s-rollup-config.js" % module_name)
    ctx.actions.write(
        output=rollup_config_file,
        content=rollup_config_content)

    node_modules_file = ctx.actions.declare_file("%s-node_modules" % module_name)
    ctx.actions.write(
        output=node_modules_file,
        content="\n".join(all_js.node_modules.keys()))

    inputs = all_js.js_and_sourcemap_files
    if bundle_type == "vendor_only":
        inputs = [node_modules_file]

    ctx.action(
        command="echo $(pwd);NODE_PATH=%s %s %s -c %s" % (
            node_modules_path,
            node_executable.path,
            rollup_script.path,
            rollup_config_file.path,
        ),
        inputs=inputs,
        outputs = [dest_file, sourcemap_file],
        progress_message = "running rollup js '%s', %s..." % (module_name, bundle_type),
        tools = [
            node_executable,
            rollup_script,
            rollup_config_file,
            entrypoint_js_file,
        ] + ctx.attr.rollup_plugins.files.to_list()
    )

    return [DefaultInfo(files=depset([dest_file]))]

rollup_js_bundle = rule(
    implementation = _impl,

    attrs = {
      "entrypoint_js_content": attr.string(),
      "module_name": attr.string(mandatory=True),
      "vendor_module_name": attr.string(),

      "root_tsc_dep": attr.label(mandatory=True),

      "node_executable": attr.label(allow_files=True, default=Label("//:node_executable")),
      "rollup_script": attr.label(allow_files=True, default=Label("//:rollup_script")),
      "rollup_plugins": attr.label(default=Label("//:rollup_plugins")),

      "bundle_type": attr.string(mandatory=True, values=["source_only", "vendor_only", "all"])
    }
)