load(":tsc.bzl", "CumulativeJsResult")

def _impl(ctx):
    node_executable = ctx.attr.node_executable.files.to_list()[0]
    rollup_script = ctx.attr.rollup_script.files.to_list()[0]
    entrypoint_js_content = ctx.attr.entrypoint_js_content # TODO: must specify if source or all type
    module_name = ctx.attr.module_name
    library_provider_module_name = ctx.attr.library_provider_module_name # TODO: must specify if source type
    node_modules_path = rollup_script.path.split("/node_modules/")[0] + "/node_modules"
    root_tsc_dep = ctx.attr.root_tsc_dep

    deps_files = []
    for dep in ctx.attr.deps:
        for f in dep.files.to_list():
            deps_files.append(f)

    entrypoint_js_file = ctx.actions.declare_file("%s-entrypoint.js" % module_name)
    extra_main_config_content = ""
    extra_output_config_content = ""
    node_modules_file = ctx.actions.declare_file("%s-node_modules" % module_name)
    import_path_to_js_dir = {}
    inputs = []

    if len(ctx.attr.provides_node_libraries) > 0:
        vendor_js_import_statements = []
        vendor_js_exports = []

        for node_module_name in ctx.attr.provides_node_libraries:
            exported_node_module_name = ctx.attr.provides_node_libraries[node_module_name]
            vendor_js_import_statements.append("import * as %s from '%s';" % (exported_node_module_name, node_module_name))
            vendor_js_exports.append("  %s" % exported_node_module_name)

        vendor_js_entrypoint_content = """
        %s

        export default {
        %s
        };
            """ % ("\n".join(vendor_js_import_statements), ",\n".join(vendor_js_exports))

        ctx.actions.write(
            output=entrypoint_js_file,
            content=vendor_js_entrypoint_content)

        ctx.actions.write(
            output=node_modules_file,
            content="\n".join(ctx.attr.provides_node_libraries.keys()))

        inputs = [node_modules_file]

    else:
        if CumulativeJsResult not in root_tsc_dep:
            fail("root_tsc_dep must be a tsc target")

        ctx.actions.write(
            output=entrypoint_js_file,
            content=entrypoint_js_content)

        ctx.actions.write(
            output=node_modules_file,
            content="[none]")

        cumulative_js_result = root_tsc_dep[CumulativeJsResult]
        import_path_to_js_dir = cumulative_js_result.import_path_to_js_dir
        if import_path_to_js_dir == None:
            import_path_to_js_dir = {}

        inputs = cumulative_js_result.js_and_sourcemap_files


    if len(ctx.attr.uses_node_libraries) > 0:
        source_js_vendored_externals = []
        source_js_vendored_globals = []

        for node_module_name in ctx.attr.uses_node_libraries:
            exported_node_module_name = ctx.attr.uses_node_libraries[node_module_name]
            source_js_vendored_externals.append("  '%s'" % node_module_name)
            source_js_vendored_globals.append("  '%s' : '%s.%s'" % (node_module_name, library_provider_module_name, exported_node_module_name))

        extra_output_config_content = """
        ,
        globals: {
          %s
        }
          """ % ",\n".join(source_js_vendored_globals)

        extra_main_config_content = """
        external: [
          %s
        ],
          """ % ",\n".join(source_js_vendored_externals)

    alias_entries = []
    for import_path in import_path_to_js_dir:
        alias_entries.append("'%s' : path.resolve(process.cwd(), './%s')" % (import_path, import_path_to_js_dir[import_path]))
    alias_str = "{\n" + ",\n".join(alias_entries) + "}\n"

    dest_file = ctx.actions.declare_file(module_name + ".js")
    sourcemap_file = ctx.actions.declare_file(module_name + ".js.map")

    # transitive deps are not properly imported without the includePaths fix, detailed here:
    # https://github.com/rollup/rollup-plugin-node-resolve/issues/105#issuecomment-332640015

    rollup_config_content = """
const path = require('path');
import commonjs from 'rollup-plugin-commonjs';
import alias from 'rollup-plugin-alias';
import resolve from 'rollup-plugin-node-resolve';
import includePaths from 'rollup-plugin-includepaths';
import builtins from 'rollup-plugin-node-builtins';
import globals from 'rollup-plugin-node-globals';

export default {
  input: '%s',
  output: {
    file: '%s',
    format: 'iife',
    sourcemap: true,
    sourcemapFile: '%s',
    name: '%s'
    %s
  },
  %s
  plugins: [
    includePaths({
      paths: ['%s']
    }),
    alias(
      %s
    ),
    resolve({
      preferBuiltins: false,

      customResolveOptions: {
        moduleDirectory: '%s'
      }
    }),
    commonjs(),
    builtins(),
    globals()
  ]

};
    """ % (
      entrypoint_js_file.path,
      dest_file.path,
      sourcemap_file.path,
      module_name,
      extra_output_config_content,
      extra_main_config_content,
      node_modules_path,
      alias_str,
      node_modules_path,
    )

    rollup_config_file = ctx.actions.declare_file("%s-rollup-config.js" % module_name)
    ctx.actions.write(
        output=rollup_config_file,
        content=rollup_config_content)

    ctx.action(
        command="echo $(pwd); NODE_DEBUG=foo NODE_PATH=%s %s %s -c %s" % (
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
        ] + ctx.attr.rollup_plugins.files.to_list() + deps_files
    )

    return [DefaultInfo(files=depset([dest_file]))]

rollup_js_bundle = rule(
    implementation = _impl,

    attrs = {
      "entrypoint_js_content": attr.string(),
      "module_name": attr.string(mandatory=True),
      "library_provider_module_name": attr.string(),

      "root_tsc_dep": attr.label(),
      "deps": attr.label_list(default=[]),
      "provides_node_libraries": attr.string_dict(),
      "uses_node_libraries": attr.string_dict(),

      "node_executable": attr.label(allow_files=True, mandatory=True),
      "rollup_script": attr.label(allow_files=True, mandatory=True),
      "rollup_plugins": attr.label(mandatory=True),
    }
)