export precompileActivator, precompileDeactivator, precompilePath, @snoopiBot

"""
    precompilePather(packageName::String)

To get the path of precompile_packageName.jl file

Written exclusively for SnoopCompile Github actions.
# Examples
```julia
precompilePath, precompileFolder = precompilePather("MatLang")
```
"""
function precompilePather(packageName::String)
    return "\"../deps/SnoopCompile/precompile/precompile_$packageName.jl\"",
    "$(pwd())/deps/SnoopCompile/precompile/"
end

precompilePather(packageName::Symbol) = precompilePather(string(packageName))
precompilePather(packageName::Module) = precompilePather(string(packageName))

################################################################

function precompileRegex(precompilePath)
    # https://stackoverflow.com/questions/3469080/match-whitespace-but-not-newlines
    # {1,} for any number of spaces
    c1 = Regex("#[^\\S\\r\\n]{0,}include\\($(precompilePath)\\)")
    c2 = r"#\s{0,}_precompile_\(\)"
    a1 = "include($precompilePath)"
    a2 = "_precompile_()"
    return c1, c2, a1, a2
end
################################################################

"""
    precompileActivator(packagePath, precompilePath)

Activates precompile of a package by adding or uncommenting include() of *.jl file generated by SnoopCompile and _precompile_().

Written exclusively for SnoopCompile Github actions.
"""
function precompileActivator(packagePath::String, precompilePath::String)

    file = open(packagePath,"r")
    packageText = Base.read(file, String)
    close(file)

    c1, c2, a1, a2 = precompileRegex(precompilePath)

    # Checking availability of _precompile_ code
    commented = occursin(c1, packageText) && occursin(c2, packageText)
    available = occursin(a1, packageText) && occursin(a2, packageText)

    if commented
        packageEdited = foldl(replace,
                     (
                      c1 => a1,
                      c2 => a2,
                     ),
                     init = packageText)

                     file = open(packagePath,"w")
                     Base.write(file, packageEdited)
                     close(file)
        println("precompile is activated")
    elseif available
        # do nothing
        println("precompile is already activated")
    else
        # TODO: add code automatiaclly
        error(""" add the following codes into your package:
         include($precompilePath)
         _precompile_()
         """)
    end

end

"""
    precompileDeactivator(packagePath, precompilePath)

Deactivates precompile of a package by commenting include() of *.jl file generated by SnoopCompile and _precompile_().

Written exclusively for SnoopCompile Github actions.
"""
function precompileDeactivator(packagePath::String, precompilePath::String)

    file = open(packagePath,"r")
    packageText = Base.read(file, String)
    close(file)

    c1, c2, a1, a2 = precompileRegex(precompilePath)

    # Checking availability of _precompile_ code
    commented = occursin(c1, packageText) && occursin(c2, packageText)
    available = occursin(a1, packageText) && occursin(a2, packageText)

    if available && !commented
        packageEdited = foldl(replace,
                     (
                      a1 => "#"*a1,
                      a2 => "#"*a2,
                     ),
                     init = packageText)

                    file = open(packagePath,"w")
                    Base.write(file, packageEdited)
                    close(file)
        println("precompile is deactivated")
    elseif commented
        # do nothing
        println("precompile is already deactivated")
    else
        # TODO: add code automatiaclly
        error(""" add the following codes into your package:
         include($precompilePath)
         _precompile_()
         """)
    end

end

"""
    snoopiBot(packageName::String, snoopScript)

macro that generates precompile files and includes them in the package. Calls other utitlities.
"""
macro snoopiBot(packageName::String, snoopScript::Expr)
    ################################################################
    packagePath = joinpath(pwd(),"src","$packageName.jl")
    precompilePath, precompileFolder = precompilePather(packageName)

    quote
        packageSym = Symbol($packageName)
        ################################################################
        using SnoopCompile
        ################################################################
        precompileDeactivator($packagePath, $precompilePath);
        ################################################################

        ### Log the compiles
        data = @snoopi begin
            $(esc(snoopScript))
        end

        ################################################################
        ### Parse the compiles and generate precompilation scripts
        pc = SnoopCompile.parcel(data)
        onlypackage = Dict( packageSym => sort(pc[packageSym]) )
        SnoopCompile.write($precompileFolder,onlypackage)
        ################################################################
        precompileActivator($packagePath, $precompilePath)
    end

end

macro snoopiBot(packageName::String)
    package = Symbol(packageName)
    snoopScript = :(
        using package, Pkg; Pkg.test(packageName)
    )
    return quote
        @snoopiBot $packageName $(esc(snoopScript))
    end
end
