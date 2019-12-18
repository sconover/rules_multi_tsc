load("//private:tsc.bzl", _tsc = "tsc")
load("//private:typings.bzl", _typings = "typings")
load("//private:rollup_js_source_bundle.bzl", _rollup_js_source_bundle = "rollup_js_source_bundle")
load("//private:rollup_js_vendor_bundle.bzl", _rollup_js_vendor_bundle = "rollup_js_vendor_bundle")
load("//private:uglify_es.bzl", _uglify_es = "uglify_es")


tsc = _tsc
rollup_js_source_bundle = _rollup_js_source_bundle
rollup_js_vendor_bundle = _rollup_js_vendor_bundle
typings = _typings
uglify_es = _uglify_es
