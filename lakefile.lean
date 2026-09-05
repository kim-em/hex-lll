import Lake
open System Lake DSL

package «hex-lll» where

  leanOptions := #[⟨`doc.verso, true⟩, ⟨`doc.verso.suggestions, false⟩]
require HexBasic from git
  "https://github.com/leanprover/hex-basic.git" @ "6ad58796dca6bae4936003412816e4e844055558"
require HexMatrix from git
  "https://github.com/leanprover/hex-matrix.git" @ "b55720b4d45a4701660eccc557022d6cb4016eaa"
require HexGramSchmidt from git
  "https://github.com/leanprover/hex-gram-schmidt.git" @ "61b1a524edf8754d6c8c7f1e5df1e557d2d816fd"

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
