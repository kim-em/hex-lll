import Lake
open System Lake DSL

package «hex-lll» where

  leanOptions := #[⟨`doc.verso, true⟩, ⟨`doc.verso.suggestions, false⟩]
require HexBasic from git
  "https://github.com/leanprover/hex-basic.git" @ "da8a864cd17ccca780d8c76af403e88585bc4734"
require HexMatrix from git
  "https://github.com/leanprover/hex-matrix.git" @ "25cfbbd8a689eb782fad408c46a9c1796dd943b2"
require HexGramSchmidt from git
  "https://github.com/leanprover/hex-gram-schmidt.git" @ "b508982f1e270918d76b61a35e4471975a3498b1"

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
