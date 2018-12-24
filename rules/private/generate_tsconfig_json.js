const assert = require("assert")
const fs = require("fs")
const path = require('path')

assert(process.argv.length==4 && fs.existsSync(process.argv[2]), `input to tsconfig generator not found. argv: ${process.argv}`)

const inputFile = process.argv[2]
const pwd = process.argv[3]

const inputJson = JSON.parse(fs.readFileSync(inputFile, "utf8"))

var tsconfigJson = null
try {
  tsconfigJson = JSON.parse(fs.readFileSync(inputJson["tsconfig_template_json_file"], "utf8"))
} catch (error) {
  console.error(`Error occurred while attempting to parse ${inputJson["tsconfig_template_json_file"]}`, error)
  process.exit(1)
}

if (tsconfigJson["compilerOptions"] == null) {
  tsconfigJson["compilerOptions"] = {}
}

tsconfigJson["compilerOptions"]["declaration"] = true // force always generating .d.ts files
tsconfigJson["compilerOptions"]["outDir"] = inputJson["out_dir"]
tsconfigJson["compilerOptions"]["paths"] = inputJson["paths_mapping"]

tsconfigJson["files"] = inputJson["srcs"].map(src => path.join(inputJson["package_relative_path"], src))

process.stdout.write(JSON.stringify(tsconfigJson, null, "  "))