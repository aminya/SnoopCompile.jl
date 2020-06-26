using Pkg
Pkg.activate()
Pkg.add([
  "SnoopCompileCore",
  "SnoopCompileAnalysis",
  "SnoopCompileBot",
])
Pkg.resolve()
