export precompile_activator, precompile_deactivator, precompile_pather, BotConfig, @snoopi_bot, @snoopi_bench

const UStrings = Union{AbstractString,Regex,AbstractChar}
################################################################
"""
    BotConfig

Config object that holds the options and configuration for the SnoopCompile bot. This object is fed to the `@snoopi_bot`.

# Arguments:
- `packageName::String`
- `subst::Vector{Pair{UStrings, UStrings}}` : to replace a packages precompile setences with another's package like `["ImageTest" => "Images"]`. `UStrings` is every string like type that `replace()` has a method for.
- `blacklist::Vector{UStrings}` : to remove some precompile sentences
- `os`::Vector{String} or nothing : give the list of os that you want to generate precompile signatures for. Each element will call a `Sys.is\$eachos()` function.
"""
struct BotConfig
    packageName::String
    subst::Vector{Pair{T1, T2}} where {T1<:UStrings, T2 <: UStrings}
    blacklist::Vector{T3} where {T3<:UStrings}
    os::Vector{String}
end

function BotConfig(packageName::String; subst::Vector{Pair{T1, T2}} where {T1<:UStrings, T2 <: UStrings} = Vector{Pair{String, String}}(), blacklist::Vector{T3} where {T3<:UStrings}= String[], os::Union{Vector{String}, Nothing} = nothing)
    return BotConfig(packageName, subst, blacklist, os)
end

include("bot/botutils.jl")
include("bot/precompile_include.jl")
include("bot/(de)activator.jl")
include("bot/snoopi_bot.jl")
include("bot/snoopi_bench.jl")


# deprecation and backward compatiblity
macro snoopiBot(args...)
     f, l = __source__.file, __source__.line
     Base.depwarn("`@snoopiBot` at $f:$l is deprecated, rename the macro to `@snoopi_bot`.", Symbol("@snoopiBot"))
     return esc(:(@snoopi_bot($(args...))))
end
macro snoopiBench(args...)
    f, l = __source__.file, __source__.line
    Base.depwarn("`@snoopiBench` at $f:$l is deprecated, rename the macro to `@snoopi_bench`.", Symbol("@snoopiBench"))
    return esc(:(@snoopi_bench($(args...))))
end

@eval @deprecate $(Symbol("@snoopiBot")) $(Symbol("@snoopi_bot"))
@eval @deprecate $(Symbol("@snoopiBench")) $(Symbol("@snoopi_bench"))
