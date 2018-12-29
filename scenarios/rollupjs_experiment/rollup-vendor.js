import resolve from 'rollup-plugin-node-resolve'
import commonjs from 'rollup-plugin-commonjs'

export default {
  input: 'vendor.js',
  output: {
    dir: "dist",
    format: 'iife',
    sourcemap: true,
    name: "vendor",
    file: "dist/vendor.js",
    intro: 'window.global = window'
  },
  plugins: [
    resolve({
      preferBuiltins: false
    }),
    commonjs()
  ]
}