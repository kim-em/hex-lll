import Lake
open System Lake DSL

package «hex-lll» where

  leanOptions := #[⟨`doc.verso, true⟩, ⟨`doc.verso.suggestions, false⟩]
require HexBasic from git
  "https://github.com/leanprover/hex-basic.git" @ "1a0fff2c8f545753b01cff0d941bf48f945cd299"
require HexMatrix from git
  "https://github.com/leanprover/hex-matrix.git" @ "f857b2b4495dc8d9ba6583d559d2b885ccbf40fc"
require HexGramSchmidt from git
  "https://github.com/leanprover/hex-gram-schmidt.git" @ "6458852e64832f9fd708f45b822826c823a9bd5a"

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
  precompileModules := true
  extraDepTargets := #[`hexlllffi]
  moreLinkArgs :=
    if System.Platform.isOSX then
      #[]
    else
      #["-ldl"]

lean_exe hexlll_external_reduction where
  root := `HexLLL.ExternalReduction
