# display
@nospecialize

function show_pipeline_function(io::IO, f1::Base.Fix1)
    print(io, "(x->")
    show_pipeline_function(io, f1.f)
    print(io, '(', f1.x, ", x))")
end
function show_pipeline_function(io::IO, f2::Base.Fix2)
    print(io, "(x->")
    show_pipeline_function(io, f2.f)
    print(io, "(x, ", f2.x, "))")
end
function show_pipeline_function(io::IO, a::ApplyN)
    print(io, "(args...->")
    show_pipeline_function(io, a.f)
    _nth(a) == 0 ?
        print(io, "()") :
        print(io, "(args[", _nth(a), "]))")
end
function show_pipeline_function(io::IO, a::ApplySyms)
    print(io, "((; kwargs...)->")
    show_pipeline_function(io, a.f)
    print(io, "(kwargs[", '(', _syms(a), ')', "]...))")
end
function show_pipeline_function(io::IO, fr::FixRest)
    show_pipeline_function(io, fr.f)
    print(io, '(')
    join(io, fr.arg, ", ")
    print(io, ')')
end
function show_pipeline_function(io::IO, c::ComposedFunction, nested=false)
    if nested
        show_pipeline_function(io, c.outer, nested)
        print(io, " ∘ ")
        show_pipeline_function(io, c.inner, nested)
    else
        print(io, '(', sprint(show_pipeline_function, c, true), ')')
    end
end
show_pipeline_function(io::IO, f, _) = show_pipeline_function(io, f)
show_pipeline_function(io::IO, f) = show(io, f)

_show_pipeline_fixf(io::IO, g, name) = (show_pipeline_function(io, g); print(io, '(', name, ')'))
_show_pipeline_fixf(io::IO, g::Base.Fix1, name) = print(io, g.f, '(', g.x, ", ", name, ')')
_show_pipeline_fixf(io::IO, g::Base.Fix2, name) = print(io, g.f, '(', name, ", ", g.x, ')')
function _show_pipeline_fixf(io::IO, g::Pipelines, name)
    _prefix = get(io, :pipeline_display_prefix, nothing)
    prefix = isnothing(_prefix) ? "  " : "$(_prefix)  ╰─ "
    print(io, '(')
    show_pipeline(io, g; flat = get(io, :compact, false), prefix)
    print(io, '\n', _prefix, ')', '(', name, ')')
end

function show_pipeline_function(io::IO, p::Pipeline)
    if p.f isa ApplyN
        n = _nth(p.f)
        g = p.f.f
        if n == 0
            _show_pipeline_fixf(io, g, "")
        elseif n == 1
            _show_pipeline_fixf(io, g, :source)
        elseif n == 2
            if g isa ApplySyms
                syms = _syms(g)
                _show_pipeline_fixf(io, g.f, syms isa Tuple ? join(map(x->"target.$x", syms), ", ") : "target.$syms")
            else
                _show_pipeline_fixf(io, g, :target)
            end
        else
            print(io, p.f)
        end
    else
        _show_pipeline_fixf(io, p.f, "source, target")
    end
end

function show_pipeline_function(io::IO, p::PipeGet)
    name = target_name(p)
    if name isa Tuple
        print(io, "(target.")
        join(io, name, ", target.")
        print(io, ')')
    else
        print(io, "(target.$name)")
    end
end

show_pipeline_function(io::IO, p::PipeVar) = show_pipeline_function(io, p.f.f.x)

function Base.show(io::IO, p::Pipeline)
    print(io, "Pipeline{")
    name = target_name(p)
    name isa Tuple ? (print(io, '('); join(io, name, ", "); print(io, ')')) : print(io, name)
    print(io, "}(")
    show_pipeline_function(io, p)
    print(io, ')')
end

function show_pipeline(io::IO, ps::Pipelines; flat=false, prefix=nothing)
    print(io, "Pipelines")
    flat || print(io, ":\n")
    n = length(ps.pipes)
    sprefix = isnothing(prefix) ? "  " : "$prefix"
    flat && print(io, '(')
    io = IOContext(io, :pipeline_display_prefix => sprefix)
    for (i, p) in enumerate(ps.pipes)
        flat || print(io, sprefix)

        if p isa PipeGet
            print(io, "target := ")
            show_pipeline_function(io, p)
        else
            print(io, "target[")
            name = target_name(p)
            if name isa Symbol
                print(io, name)
            else
                print(io, '(')
                join(io, name, ", ")
                print(io, ')')
            end
            print(io, "] := ")
            show_pipeline_function(io, p)
        end

        if i != n
            flat ? print(io, "; ") : print(io, '\n')
        end
    end
    flat && print(io, ')')
end

function Base.show(io::IO, ps::Pipelines)
    prefix = get(io, :pipeline_display_prefix, nothing)
    flat = get(io, :compact, false)
    show_pipeline(io, ps; flat, prefix)
end

@specialize
