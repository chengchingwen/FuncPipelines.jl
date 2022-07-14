using FuncPipelines
using FuncPipelines: get_pipeline_func, target_name
using Test

# quick and dirty macro for making @inferred as test case
macro test_inferred(ex)
    esc(quote
        @test begin
            @inferred $ex
            true
        end
    end)
end

function trunc_and_pad(a, b, c) end
trunc_and_pad(b, c) = FuncPipelines.FixRest(trunc_and_pad, b, c)

@testset "FuncPipelines.jl" begin
    @testset "Pipelines" begin
        p1 = Pipeline{:x}((x,_)->x)
        p2 = Pipeline{(:sinx, :cosx)}((x, _)->sincos(x))
        p3 = Pipeline{:z}(x->3x+5, :x)
        ps1 = Pipelines(p1, p2)
        ps2 = Pipelines(Pipeline{:x}(identity, 1), Pipeline{(:sinx, :cosx)}(y->sincos(y.x), 2))
        ps3 = ps2 |> PipeGet{:x}()
        ps4 = ps2 |> PipeGet{(:x, :sinx)}()
        ps5 = p1 |> p2 |> Pipeline{:xsinx}(*, (:x, :sinx))

        p4 = Pipeline{:r}(p3)
        p5 = Pipeline(p3, :y)
        p6 = Pipeline{:r}(p3, :y)

        @test ps5[begin:end] == ps5
        @test get_pipeline_func(ps2[1]) === identity
        @test Base.setindex(ps1, p2, 1)[1] === p2
        @test replace(p->target_name(p) == :x ? Pipeline{:y}(p) : p, ps1)[1] === Pipeline{:y}(p1)

        @test p3(0, (x = 2,)) == (x = 2, z = 11)
        @test p4(0, (x = 2,)) == (x = 2, r = 11)
        @test p5(0, (x = 2, y = 1)) == (x = 2, y = 1, z = 8)
        @test p6(0, (x = 2, y = 1)) == (x = 2, y = 1, r = 8)
        @test ps1(0.5) == ps2(0.5)
        @test ps3(0.2) == 0.2
        @test ps4(0.3) == (x = 0.3, sinx = sin(0.3))
        @test ps5(0.7) == (x = 0.7, sinx = sin(0.7), cosx = cos(0.7), xsinx = 0.7*sin(0.7))
        @test_inferred p1(0.3)
        @test_inferred p2(0.5)
        @test_inferred p3(0, (x = 2,))
        @test_inferred ps1(0.5)
        @test_inferred ps2(0.5)
        @test_inferred ps3(0.5)
        @test_inferred ps5(0.5)

        @test p1 |> p2 == ps1
        @test ps1 |> p1 == Pipelines(p1, p2, p1)
        @test p1 |> ps1 == Pipelines(p1, p1, p2)
        @test ps1 |> ps1 == Pipelines(p1, p2, p1, p2)
        @test collect(ps1) == [p1, p2]
        @test_throws Exception Pipeline{:x}(identity, 3)
        @test_throws Exception Pipeline{()}(identity)
        @test_throws Exception Pipelines(())

        @testset "show" begin
            @test sprint(show, Pipeline{:x}(-, 1)) == "Pipeline{x}(-(source))"
            @test sprint(show, Pipeline{(:sinx, :cosx)}(sincos, 1)) == "Pipeline{(sinx, cosx)}(sincos(source))"
            @test sprint(show, Pipeline{(:sinx, :cosx)}(sincos, :x)) == "Pipeline{(sinx, cosx)}(sincos(target.x))"
            @test sprint(show, Pipeline{(:tanx, :tany)}(Base.Fix1(map, tan), 2)) == "Pipeline{(tanx, tany)}(map(tan, target))"
            @test sprint(show, Pipeline{:x2}(Base.Fix2(/, 2), :x)) == "Pipeline{x2}(/(target.x, 2))"
            @test sprint(show, Pipeline{:z}(sin∘cos, :x)) == "Pipeline{z}((sin ∘ cos)(target.x))"
            @test sprint(show, Pipeline{:z}(Base.Fix1(*, 2) ∘ Base.Fix2(+, 1))) == "Pipeline{z}(((x->*(2, x)) ∘ (x->+(x, 1)))(source, target))"
            @test sprint(show, Pipeline{:tok}(trunc_and_pad(nothing, 0), :tok)) == "Pipeline{tok}(trunc_and_pad(nothing, 0)(target.tok))"
            @test sprint(show, PipeGet{:x}()) == "Pipeline{x}((target.x))"
            @test sprint(show, PipeGet{(:a, :b)}()) == "Pipeline{(a, b)}((target.a, target.b))"

            foo(x, y) = x * y.sinx
            @test sprint(
                show,
                Pipeline{:x}(identity, 1) |> Pipeline{(:sinx, :cosx)}(sincos, :x) |>
                Pipeline{:xsinx}(foo) |> PipeGet{(:cosx, :xsinx)}()
                ; context=:compact=>true
            ) ==
                "Pipelines(target[x] := identity(source); target[(sinx, cosx)] := sincos(target.x); target[xsinx] := foo(source, target); target := (target.cosx, target.xsinx))"
        end
    end
end
