struct Pipeline{name, F}
    f::F
    function Pipeline{name, F}(f::F) where {name, F}
        name isa Symbol || name isa NTuple{N, Symbol} where N && !(name isa Tuple{}) ||
            error("Pipeline name must be a Symbol or Tuple of Symbol: get $name")
        return new{name, F}(f)
    end
end
Pipeline{name}(f) where name = Pipeline{name, typeof(f)}(f)
Pipeline{name}(f::ApplyN{N}) where {name, N} = (N == 1 || N == 2) ? Pipeline{name, typeof(f)}(f) : error("attempt to access $n-th argument while pipeline only take 2")

Pipeline{name}(f, n::Int) where name = Pipeline{name}(ApplyN{n}(f))
Pipeline{name}(f, syms::Union{Symbol, Tuple{Vararg{Symbol}}}) where name = Pipeline{name}(ApplySyms{syms}(f), 2)

# replace name or syms
Pipeline{name}(p::Pipeline) where name = Pipeline{name}(p.f)
function Pipeline{name}(p::Pipeline, syms::Union{Symbol, Tuple{Vararg{Symbol}}}) where name
    @assert p.f isa ApplyN{2} && p.f.f isa ApplySyms "Cannot change applied symbols on a pipeline not operating on target"
    f = p.f.f
    S = _syms(f)
    @assert typeof(S) == typeof(syms) "Cannot change applied symbols to uncompatible one: form $S to $syms"
    return Pipeline{name}(ApplySyms{syms}(f.f), 2)
end
Pipeline(p::Pipeline{name}, syms::Union{Symbol, Tuple{Vararg{Symbol}}}) where name = Pipeline{name}(p, syms)

"""
    target_name(p::Pipeline{name}) where name = name

Get the target symbol(s).
"""
target_name(p::Pipeline{name}) where name = name

@inline _result_namedtuple(p::Pipeline, result) = _result_namedtuple(target_name(p), result)
@inline _result_namedtuple(name::Symbol, result) = _result_namedtuple((name,), result)
@inline _result_namedtuple(name::NTuple{N, Symbol} where N, result) = NamedTuple{name}((result,))
@inline _result_namedtuple(name::NTuple{N, Symbol} where N, result::Tuple) = NamedTuple{name}(result)

(p::Pipeline{name})(x, y = NamedTuple()) where name = merge(y, _result_namedtuple(p, p.f(x, y)))

struct Pipelines{T<:NTuple{N, Pipeline} where N}
    pipes::T
end
Pipelines{Tuple{}}(::Tuple{}) = error("empty pipelines")
Pipelines(p::Pipeline) = Pipelines{Tuple{typeof(p)}}((p,))
Pipelines(ps::Pipelines) = ps
Pipelines(p1, ps...) = p1 |> Pipelines(ps...)

Base.length(ps::Pipelines) = length(ps.pipes)
Base.iterate(ps::Pipelines, state=1) = iterate(ps.pipes, state)
Base.firstindex(ps::Pipelines) = firstindex(ps.pipes)
Base.lastindex(ps::Pipelines) = lastindex(ps.pipes)

@inline Base.getindex(ps::Pipelines, i) = ps.pipes[i]
Base.getindex(ps::Pipelines, i::UnitRange{<:Integer}) = Pipelines(ps.pipes[i])

(ps::Pipelines{T})(x) where T = ps(x, NamedTuple()::NamedTuple{(), Tuple{}})
function (ps::Pipelines{T})(x, y) where T
    if @generated
        body = Expr[ :(y = _pipes[$n](x, y)) for n = 1:fieldcount(T)]
        return quote
            _pipes = ps.pipes
            $(body...)
        end
    else
        foldl((y, p)->p(x, y), ps.pipes; init=y)
    end
end

Base.:(|>)(p1::Pipeline, p2::Pipeline) = Pipelines((p1, p2))
Base.:(|>)(p1::Pipelines, p2::Pipeline) = Pipelines((p1.pipes..., p2))
Base.:(|>)(p1::Pipeline, p2::Pipelines) = Pipelines((p1, p2.pipes...))
Base.:(|>)(p1::Pipelines, p2::Pipelines) = Pipelines((p1.pipes..., p2.pipes...))

"""
    PipeGet{name}()

A special pipeline that get the wanted `name`s from namedtuple.

# Example

```julia-repl
julia> p = Pipeline{:x}(identity, 1) |> Pipeline{(:sinx, :cosx)}(sincos, 1) |> PipeGet{(:x, :sinx)}()
Pipelines:
  target[x] := identity(source)
  target[(sinx, cosx)] := sincos(source)
  target := (target.x, target.sinx)

julia> p(0.5)
(x = 0.5, sinx = 0.479425538604203)

julia> p = Pipeline{:x}(identity, 1) |> Pipeline{(:sinx, :cosx)}(sincos, 1) |> PipeGet{:sinx}()
Pipelines:
  target[x] := identity(source)
  target[(sinx, cosx)] := sincos(source)
  target := (target.sinx)

julia> p(0.5)
0.479425538604203

```

"""
const PipeGet{name} = Pipeline{name, typeof(__getindex__)}

PipeGet{name}() where name = PipeGet{name}(__getindex__)
(p::PipeGet{name})(_, y) where name = __getindex__(y, name)


"""
    Pipeline{name}(f)

Create a pipeline function with name. When calling the pipeline function, mark the result with `name`.
 `f` should take two arguemnt: the input and a namedtuple (can be ignored) that the result will be
 merged to. `name` can be either `Symbol` or tuple of `Symbol`s.


    Pipeline{name}(f, n)

Create a pipline function with name. `f` should take one argument, it will be applied to either the input
 or namedtuple depend on the value of `n`. `n` should be either `1` or `2`. Equivalent to
 `f(n == 1 ? source : target)`.

    Pipeline{name}(f, syms)

Create a pipline function with name. `syms` can be either a `Symbol` or a tuple of `Symbol`s.
 Equivalent to `f(target[syms])` or `f(target[syms]...)` depends on the type of `syms`.

# Example

```julia-repl
julia> p = Pipeline{:x}(1) do x
           2x
       end
Pipeline{x}(var"#19#20"()(source))

julia> p(3)
(x = 6,)

julia> p = Pipeline{:x}() do x, y
           y.a * x
       end
Pipeline{x}(var"#21#22"()(source, target))

julia> p(2, (a=3, b=5))
(a = 3, b = 5, x = 6)

julia> p = Pipeline{:x}(y->y.a^2, 2)
Pipeline{x}(var"#23#24"()(target))

julia> p(2, (a = 3, b = 5))
(a = 3, b = 5, x = 9)

julia> p = Pipeline{(:sinx, :cosx)}(sincos, 1)
Pipeline{(sinx, cosx)}(sincos(source))

julia> p(0.5)
(sinx = 0.479425538604203, cosx = 0.8775825618903728)

julia> p = Pipeline{:z}((x, y)-> 2x+y, (:x, :y))
Pipeline{z}(var"#33#34"()(target.x, target.y))

julia> p(0, (x=3, y=5))
(x = 3, y = 5, z = 11)

```

"""
Pipeline

"""
    Pipelines(pipeline...)

Chain of `Pipeline`s.

# Example

```julia-repl
julia> pipes = Pipelines(Pipeline{:x}((x,y)->x), Pipeline{(:sinx, :cosx)}((x,y)->sincos(x)))
Pipelines:
  target[x] := var"#25#27"()(source, target)
  target[(sinx, cosx)] := var"#26#28"()(source, target)

julia> pipes(0.3)
(x = 0.3, sinx = 0.29552020666133955, cosx = 0.955336489125606)

# or use `|>`
julia> pipes = Pipeline{:x}((x,y)->x) |> Pipeline{(:sinx, :cosx)}((x,y)->sincos(x))
Pipelines:
  target[x] := var"#29#31"()(source, target)
  target[(sinx, cosx)] := var"#30#32"()(source, target)

julia> pipes(0.3)
(x = 0.3, sinx = 0.29552020666133955, cosx = 0.955336489125606)

```
"""
Pipelines
