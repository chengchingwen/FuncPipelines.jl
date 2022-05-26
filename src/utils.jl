@static if VERSION < v"1.7"
    @inline __getindex__(nt::NamedTuple, name) = name isa Symbol ? nt[name] : NamedTuple{name}(nt)
else
    @inline __getindex__(nt::NamedTuple, name) = nt[name]
end

struct FixRest{F, A<:Tuple} <: Function
    f::F
    arg::A
end
FixRest(f, arg...) = FixRest(f, arg)

(f::FixRest)(arg...) = f.f(arg..., f.arg...)

struct ApplyN{N, F} <: Function
    f::F
end
ApplyN{N}(f) where N = ApplyN{N, typeof(f)}(f)

_nth(::ApplyN{N}) where N = N

(f::ApplyN)(args...) = f.f(args[_nth(f)])

struct ApplySyms{S, F} <: Function
    f::F
end
ApplySyms{S}(f) where S = ApplySyms{S, typeof(f)}(f)

_syms(::ApplySyms{S}) where S = S

function (f::ApplySyms)(nt::NamedTuple)
    s = _syms(f)
    if s isa Tuple
        f.f(__getindex__(nt, s)...)
    else
        f.f(__getindex__(nt,s))
    end
end
