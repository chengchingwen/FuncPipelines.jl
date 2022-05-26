using FuncPipelines
using Documenter

DocMeta.setdocmeta!(FuncPipelines, :DocTestSetup, :(using FuncPipelines); recursive=true)

makedocs(;
    modules=[FuncPipelines],
    authors="chengchingwen <adgjl5645@hotmail.com> and contributors",
    repo="https://github.com/chengchingwen/FuncPipelines.jl/blob/{commit}{path}#{line}",
    sitename="FuncPipelines.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://chengchingwen.github.io/FuncPipelines.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/chengchingwen/FuncPipelines.jl",
    devbranch="main",
)
