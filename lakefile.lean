import Lake
open System Lake DSL

package «hex-lll» where

  leanOptions := #[⟨`doc.verso, true⟩, ⟨`doc.verso.suggestions, false⟩]
require HexBasic from git
  "https://github.com/leanprover/hex-basic.git" @ "2d7f55d190cc2df9c9bf55437f344e65fbddc7c0"
require HexMatrix from git
  "https://github.com/leanprover/hex-matrix.git" @ "049bf8e57b33cb87b4012ed9d2da4cce0af296d9"
require HexGramSchmidt from git
  "https://github.com/leanprover/hex-gram-schmidt.git" @ "a6f9a5a3cefa8383a3736b35c94be35e1d830cf5"

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
