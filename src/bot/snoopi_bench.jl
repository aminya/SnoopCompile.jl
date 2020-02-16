################################################################
"""
    timesum(snoop)

Calculates and prints the total time measured by a snoop macro.

It is used inside @snoopi_bench. Julia can cache inference results so to measure the effect of adding _precompile_() sentences generated by snoopi to your package, use the [`@snoopi_bench`](@ref). This benchmark measures inference time taken during loading and running of a package.

# Examples
```julia
using SnoopCompile
data = @snoopi begin
    include(joinpath(dirname(dirname(pathof(MatLang))),"test","runtests.jl"))
end;
println(timesum(data));
```

## Manual Benchmark (withtout using [`@snoopi_bench`](@ref))
- dev your package

- comment the precompile part of your package (`include()` and `_precompile_()`)
- run the following benchmark
- restart Julia

- uncomment the precompile part of your package (`include()` and `_precompile_()`)
- run the following benchmark
- restart Julia

### Benchmark
```julia
using SnoopCompile

println("Package load time:")
loadSnoop = @snoopi using MatLang

timesum(loadSnoop)

println("Running Examples/Tests:")
runSnoop = @snoopi begin
    using MatLang
    include(joinpath(dirname(dirname(pathof(MatLang))),"test","runtests.jl"))
end

timesum(runSnoop)
```
"""
function timesum(snoop::Vector{Tuple{Float64, Core.MethodInstance}})
    if isempty(snoop)
        return 0.0
    else
        return sum(first, snoop)
    end
end

################################################################
"""
    @snoopi_bench(package_name::String, snoop_script::Expr)
    @snoopi_bench(package_name::String)

Performs an infertime benchmark by activating and deactivating the _precompile_()
# Examples
Benchmarking the load infer time
```julia
println("loading infer benchmark")

@snoopi_bench "MatLang" using MatLang
```

Benchmarking the example infer time
```julia
println("examples infer benchmark")

@snoopi_bench "MatLang" begin
    using MatLang
    example_path = joinpath(dirname(dirname(pathof(MatLang))), "examples")
    # include(joinpath(example_path,"Language_Fundamentals", "usage_Entering_Commands.jl"))
    include(joinpath(example_path,"Language_Fundamentals", "usage_Matrices_and_Arrays.jl"))
    include(joinpath(example_path,"Language_Fundamentals", "Data_Types", "usage_Numeric_Types.jl"))
end
```
"""
macro snoopi_bench(package_name::String, snoop_script::Expr)

    ################################################################
    package_path = joinpath(pwd(),"src","$package_name.jl")
    juliaCode = """
    using SnoopCompile; data = @snoopi begin
        $(string(snoop_script));
    end;
    @info(timesum(data));
    """
    julia_cmd = `julia --project=@. -e "$juliaCode"`
    quote
        package_sym = Symbol($package_name)
        ################################################################
        using SnoopCompile
        @info("""*******************
        Benchmark Started
        *******************
        """)
        ################################################################
        @info("""Precompile Deactivated Benchmark
        ------------------------
        """)
        precompile_deactivator($package_path);
        ### Log the compiles
        run($julia_cmd)
        ################################################################
        @info("""Precompile Activated Benchmark
        ------------------------
        """)
        precompile_activator($package_path);
        ### Log the compiles
        run($julia_cmd)
        @info("""*******************
        Benchmark Finished
        *******************
        """)
    end

end

"""
    @snoopi_bench package_name::String

Benchmarking the infer time of the tests:
```julia
@snoopi_bench "MatLang"
```
"""
macro snoopi_bench(package_name::String)
    package = Symbol(package_name)
    snoop_script = :(
        using $(package);
        runtestpath = joinpath(dirname(dirname(pathof($(package)))), "test", "runtests.jl");
        include(runtestpath);
    )
    return quote
        @snoopi_bench $package_name $(snoop_script)
    end
end
