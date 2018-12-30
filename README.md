Please read [this post](https://github.com/Microsoft/TypeScript/issues/13538#issuecomment-293219979).

Provides a single key rule, `tsc`, which allows a typescript project to be split into small libraries, and for those libraries to be independently compiled.

In contrast to [rules_typescript](https://github.com/bazelbuild/rules_typescript), it depends on a few core bazel rules and has no other dependencies. You plug in your own nodejs executable and tsc implementation.

Comes with bonus rules for creating and minifying js bundles, from the results of tsc compilation.

## Installation

TODO

## Example usage

```python
load("@rules_multi_tsc//:def.bzl", "tsc")

tsc(
    name="tsc",
    ts_path="polygon",
    srcs=glob(["*.ts"]),
    deps=["//02_dependent/basics:tsc"],

    node_executable="@node//:bin/node",
    tsc_script="@node_modules_archive//:node_modules/typescript/lib/tsc.js",
    tsconfig_json="//:tsconfig.json",
)
```

This example compiles .ts files in the current directory,
and makes associated typescript definitions available at the `polygon` path, e.g.:

```typescript
import {Hexagon} from "polygon/hexagon"
```

Please see the [scenarios](./scenarios) directory for more examples.