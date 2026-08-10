import Lake
open System Lake DSL

package «hex-lll» where

  leanOptions := #[⟨`doc.verso, true⟩, ⟨`doc.verso.suggestions, false⟩]
require HexBasic from git
  "https://github.com/leanprover/hex-basic.git" @ "365881fb205210e8d27c5eb011f7ddb3fe020373"
require HexMatrix from git
  "https://github.com/leanprover/hex-matrix.git" @ "e76a18ae921d8d8907c8ea37235a0ca5b94698cd"
require HexGramSchmidt from git
  "https://github.com/leanprover/hex-gram-schmidt.git" @ "5bb2f1b040ff2ed481233ad396cf50cd86d26cc3"

private def hexlllProviderOTarget (pkg : Package) : FetchM (Job FilePath) := do
  let oFile := pkg.dir / defaultBuildDir / "HexLLL" / "ffi" / "lean_hexlll_provider.o"
  let srcTarget ← inputTextFile <| pkg.dir / "HexLLL" / "ffi" / "lean_hexlll_provider.c"
  buildFileAfterDep oFile srcTarget fun srcFile => do
    let flags := #["-I", (← getLeanIncludeDir).toString, "-fPIC"]
    compileO oFile srcFile flags

extern_lib hexlllffi (pkg) := do
  let name := nameToStaticLib "hexlllffi"
  let oTarget ← hexlllProviderOTarget pkg
  buildStaticLib (pkg.staticLibDir / name) #[oTarget]

@[default_target]
lean_lib HexLLL where
  extraDepTargets := #[`hexlllffi]
  moreLinkArgs :=
    if System.Platform.isOSX then
      #[]
    else
      #["-ldl"]

lean_exe hexlll_external_reduction where
  root := `HexLLL.ExternalReduction
