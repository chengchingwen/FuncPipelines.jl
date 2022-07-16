@static if VERSION < v"1.7"
    function __replace(f::Function, ps::Tuple, count)
        if count == 0 || isempty(ps)
            return ps
        else
            p1 = first(ps)
            y = f(p1)
            return (y, __replace(f, Base.tail(ps), count - !==(p1, y))...)
        end
    end
    Base.replace(f::Function, ps::Pipelines; count::Integer = typemax(Int)) = Pipelines(__replace(f, ps.pipes, Base.check_count(count)))
else
    Base.replace(f::Function, ps::Pipelines; count::Integer = typemax(Int)) = Pipelines(replace(f, ps.pipes; count))
end

"""
    replace(f::Function, ps::Pipelines; [count::Integer])

Return a new `Pipelines` where each `Pipeline` p in `ps` is replaced by `f(p)`.
 If count is specified, then replace at most count values in total (replacements being defined as new(x) !== x)
"""
Base.replace(f::Function, ps::Pipelines; count::Integer = typemax(Int))


"""
    replace(f::Function, p::Pipeline)

replace the function in `p` with the same target name and applied arguments.
"""
function Base.replace(f::Base.Callable, p::Pipeline)
    name = target_name(p)
    g = p.f
    if g isa ApplyN
        n = _nth(g)
        if n == 1
            h = ApplyN{1}(f)
        else
            if g.f isa ApplySyms
                h = ApplyN{2}(ApplySyms{_syms(g.f)}(f))
            else
                h = ApplyN{2}(f)
            end
        end
    else
        h = f
    end
    return Pipeline{name}(h)
end

"""
    Base.setindex(ps::Pipelines, p::Pipeline, i::Integer)

Replace the `i`-th pipeline in `ps` with `p`.
"""
Base.setindex(ps::Pipelines, p::Pipeline, i::Integer) = Pipelines(Base.setindex(ps.pipes, p, i))

"""
    get_pipeline_func(p::Pipeline)

Get the underlying function in pipeline.
"""
function get_pipeline_func(p::Pipeline)
    f = p.f
    !(f isa ApplyN) && return f
    _nth(f) != 2 && return f.f
    g = f.f
    return g isa ApplySyms ? g.f : g
end
