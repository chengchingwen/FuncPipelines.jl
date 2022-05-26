# FuncPipelines

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://chengchingwen.github.io/FuncPipelines.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://chengchingwen.github.io/FuncPipelines.jl/dev)
[![Build Status](https://github.com/chengchingwen/FuncPipelines.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/chengchingwen/FuncPipelines.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/chengchingwen/FuncPipelines.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/chengchingwen/FuncPipelines.jl)

# Pipelines

The Pipeline api help you define a series of functions that can easily be decomposed and then combined with
 other function to form a new pipeline. A function (`Pipeline`) is tagged with one (or multiple) `Symbol`s.
 The return values of that `Pipeline` will be bound to those symbols storing in a `NamedTuple`. Precisely,
 A `Pipeline` take two inputs, a regular input value (`source`) and a `NamedTuple` (`target`) that stores
 the results, applying the function to them, and then store the result with the name it carried with into `target`.
 We can then chaining multiple `Pipeline`s into a `Pipelines`. For example:

```julia
julia> pipes = Pipeline{:x}(identity, 1) |> Pipeline{(:sinx, :cosx)}((x,y)->sincos(x))

julia> pipes(0.3)
(x = 0.3, sinx = 0.29552020666133955, cosx = 0.955336489125606)

# define a series of function
julia> pipes = Pipeline{:θ}(Base.Fix1(*, 2), 1) |>
           Pipeline{(:sinθ, :cosθ)}(sincos, :θ) |>
           Pipeline{:tanθ}(2) do target
               target.sinθ / target.cosθ
           end

Pipelines:
  target[θ] := *(2, source)
  target[(sinθ, cosθ)] := sincos(target.θ)
  target[tanθ] := #68(target)

# get the wanted results
julia> pipes2 = pipes |> PipeGet{(:tanθ, :θ)}()
Pipelines:
  target[θ] := *(2, source)
  target[(sinθ, cosθ)] := sincos(target.θ)
  target[tanθ] := #68(target)
  target := (target.tanθ, target.θ)

julia> pipes2(ℯ)
(tanθ = -1.1306063769531505, θ = 5.43656365691809)

# replace some functions in pipeline
julia> pipes3 = pipes2[1] |> Pipeline{:tanθ}(tan, :θ) |> pipes2[end]
Pipelines:
  target[θ] := *(2, source)
  target[tanθ] := tan(target.θ)
  target := (target.tanθ, target.θ)

julia> pipes3(ℯ)
(tanθ = -1.1306063769531507, θ = 5.43656365691809)

# and the pipelines is type stable
julia> using Test; @inferred pipes3(ℯ)
(tanθ = -1.1306063769531507, θ = 5.43656365691809)

```
