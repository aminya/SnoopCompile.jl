using Pkg
Pkg.activate()
rootdir = dirname(@__DIR__)
Pkg.develop([
  PackageSpec(path=joinpath(rootdir,"SnoopCompileCore")),
  PackageSpec(path=joinpath(rootdir,"SnoopCompileAnalysis")),
  PackageSpec(path=joinpath(rootdir,"SnoopCompileBot")),
  PackageSpec(path=rootdir),
])
Pkg.resolve()
