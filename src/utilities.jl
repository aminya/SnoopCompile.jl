export precompileActivator, precompileDeactivator, precompilePath, @snoopiBot

"""
    precompilePath(packageName::String)

To get the path of precompile_packageName.jl file

Written exclusively for SnoopCompile Github actions.
"""
function precompilePath(packageName::String)
    return "../deps/SnoopCompile/precompile/precompile_$packageName.jl"
end

precompilePath(packageName::Symbol) = precompilePath(string(packageName))
precompilePath(packageName::Module) = precompilePath(string(packageName))

"""
    precompileActivator(packagePath, precompilePath)

Activates precompile of a package by adding or uncommenting include() of *.jl file generated by SnoopCompile and _precompile_().

Written exclusively for SnoopCompile Github actions.
"""
function precompileActivator(packagePath::String, precompilePath::String)

    file = open(packagePath,"r")
    packageText = Base.read(file, String)
    close(file)

    # Checking availability of _precompile_ code
    commented = occursin("#include($precompilePath)", packageText)  && occursin("#_precompile_()", packageText)

    available = occursin("include($precompilePath)", packageText)  && occursin("_precompile_()", packageText)

    if commented
        packageEdited = foldl(replace,
                     (
                      "#include($precompilePath)" => "include($precompilePath)",
                      "#_precompile_()" => "_precompile_()",
                     ),
                     init = packageText)

                     file = open(packagePath,"w")
                     write(file, packageEdited)
                     close(file)
    elseif available
        # do nothing
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

    # Checking availability of _precompile_ code
    commented = occursin("#include($precompilePath)", packageText)  && occursin("#_precompile_()", packageText)

    available = occursin("include($precompilePath)", packageText)  && occursin("_precompile_()", packageText)

    if available && !commented
        packageEdited = foldl(replace,
                     (
                      "include($precompilePath)" => "#include($precompilePath)",
                      "_precompile_()" => "#_precompile_()",
                     ),
                     init = packageText)

                    file = open(packagePath,"w")
                    write(file, packageEdited)
                    close(file)
    elseif commented
        # do nothing
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
macro snoopiBot(packageName::String, snoopScript)

# by default run "runtests"
# = :(using MatLang; include(joinpath(dirname(dirname(pathof(MatLang))), "test","runtests.jl")); )

    ################################################################
    packagePath = joinpath(pwd(),"src","$packageName.jl")

    quote
        ################################################################
        using SnoopCompile
        ################################################################
        const rootPath = pwd()
        precompileDeactivator($packagePath, precompilePath($packageName));
        cd(@__DIR__)
        ################################################################

        ### Log the compiles
        data = @snoopi begin
            $snoopScript
        end

        ################################################################
        ### Parse the compiles and generate precompilation scripts
        pc = SnoopCompile.parcel(data)
        onlypackage = Dict(package => sort(pc[package]))
        SnoopCompile.write("$(pwd())/precompile",onlypackage)
        ################################################################
        cd(rootPath)
        precompileActivator($packagePath, precompilePath($packageName))
    end

end
