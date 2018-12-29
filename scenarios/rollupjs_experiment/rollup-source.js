import resolve from 'rollup-plugin-node-resolve'
import commonjs from 'rollup-plugin-commonjs'

export default {
  input: 'bar.js',
  output: {
    dir: "dist",
    format: 'iife',
    name: 'source',
    sourcemap: true,
    file: "dist/source.js",
    globals: {
      'long': 'vendor._long',
      'bson': 'vendor._bson'
    }
  },
  external: ['bson', 'long'],
  plugins: [
    resolve({
      preferBuiltins: false
    }),
    commonjs()
  ]
}