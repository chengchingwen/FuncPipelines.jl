var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = FuncPipelines","category":"page"},{"location":"#FuncPipelines","page":"Home","title":"FuncPipelines","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"Documentation for FuncPipelines.","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [FuncPipelines]","category":"page"},{"location":"#FuncPipelines.PipeGet","page":"Home","title":"FuncPipelines.PipeGet","text":"PipeGet{name}()\n\nA special pipeline that get the wanted names from namedtuple.\n\nExample\n\njulia> p = Pipeline{:x}(identity, 1) |> Pipeline{(:sinx, :cosx)}(sincos, 1) |> PipeGet{(:x, :sinx)}()\nPipelines:\n  target[x] := identity(source)\n  target[(sinx, cosx)] := sincos(source)\n  target := (target.x, target.sinx)\n\njulia> p(0.5)\n(x = 0.5, sinx = 0.479425538604203)\n\njulia> p = Pipeline{:x}(identity, 1) |> Pipeline{(:sinx, :cosx)}(sincos, 1) |> PipeGet{:sinx}()\nPipelines:\n  target[x] := identity(source)\n  target[(sinx, cosx)] := sincos(source)\n  target := (target.sinx)\n\njulia> p(0.5)\n0.479425538604203\n\n\n\n\n\n\n","category":"type"},{"location":"#FuncPipelines.Pipeline","page":"Home","title":"FuncPipelines.Pipeline","text":"Pipeline{name}(f)\n\nCreate a pipeline function with name. When calling the pipeline function, mark the result with name.  f should take two arguemnt: the input and a namedtuple (can be ignored) that the result will be  merged to. name can be either Symbol or tuple of Symbols.\n\nPipeline{name}(f, n)\n\nCreate a pipline function with name. f should take one argument, it will be applied to either the input  or namedtuple depend on the value of n. n should be either 1 or 2. Equivalent to  f(n == 1 ? source : target).\n\nPipeline{name}(f, syms)\n\nCreate a pipline function with name. syms can be either a Symbol or a tuple of Symbols.  Equivalent to f(target[syms]) or f(target[syms]...) depends on the type of syms.\n\nExample\n\njulia> p = Pipeline{:x}(1) do x\n           2x\n       end\nPipeline{x}(var\"#19#20\"()(source))\n\njulia> p(3)\n(x = 6,)\n\njulia> p = Pipeline{:x}() do x, y\n           y.a * x\n       end\nPipeline{x}(var\"#21#22\"()(source, target))\n\njulia> p(2, (a=3, b=5))\n(a = 3, b = 5, x = 6)\n\njulia> p = Pipeline{:x}(y->y.a^2, 2)\nPipeline{x}(var\"#23#24\"()(target))\n\njulia> p(2, (a = 3, b = 5))\n(a = 3, b = 5, x = 9)\n\njulia> p = Pipeline{(:sinx, :cosx)}(sincos, 1)\nPipeline{(sinx, cosx)}(sincos(source))\n\njulia> p(0.5)\n(sinx = 0.479425538604203, cosx = 0.8775825618903728)\n\njulia> p = Pipeline{:z}((x, y)-> 2x+y, (:x, :y))\nPipeline{z}(var\"#33#34\"()(target.x, target.y))\n\njulia> p(0, (x=3, y=5))\n(x = 3, y = 5, z = 11)\n\n\n\n\n\n\n","category":"type"},{"location":"#FuncPipelines.Pipelines","page":"Home","title":"FuncPipelines.Pipelines","text":"Pipelines(pipeline...)\n\nChain of Pipelines.\n\nExample\n\njulia> pipes = Pipelines(Pipeline{:x}((x,y)->x), Pipeline{(:sinx, :cosx)}((x,y)->sincos(x)))\nPipelines:\n  target[x] := var\"#25#27\"()(source, target)\n  target[(sinx, cosx)] := var\"#26#28\"()(source, target)\n\njulia> pipes(0.3)\n(x = 0.3, sinx = 0.29552020666133955, cosx = 0.955336489125606)\n\n# or use `|>`\njulia> pipes = Pipeline{:x}((x,y)->x) |> Pipeline{(:sinx, :cosx)}((x,y)->sincos(x))\nPipelines:\n  target[x] := var\"#29#31\"()(source, target)\n  target[(sinx, cosx)] := var\"#30#32\"()(source, target)\n\njulia> pipes(0.3)\n(x = 0.3, sinx = 0.29552020666133955, cosx = 0.955336489125606)\n\n\n\n\n\n\n","category":"type"},{"location":"#Base.replace-Tuple{Function, Pipelines}","page":"Home","title":"Base.replace","text":"replace(f::Function, ps::Pipelines; [count::Integer])\n\nReturn a new Pipelines where each Pipeline in ps is replaced by f.  If count is specified, then replace at most count values in total (replacements being defined as new(x) !== x)\n\n\n\n\n\n","category":"method"},{"location":"#Base.setindex-Tuple{Pipelines, Pipeline, Integer}","page":"Home","title":"Base.setindex","text":"Base.setindex(ps::Pipelines, p::Pipeline, i::Integer)\n\nReplace the i-th pipeline in ps with p.\n\n\n\n\n\n","category":"method"},{"location":"#FuncPipelines.get_pipeline_func-Tuple{Pipeline}","page":"Home","title":"FuncPipelines.get_pipeline_func","text":"get_pipeline_func(p::Pipeline)\n\nGet the underlying function in pipeline.\n\n\n\n\n\n","category":"method"},{"location":"#FuncPipelines.target_name-Union{Tuple{Pipeline{name}}, Tuple{name}} where name","page":"Home","title":"FuncPipelines.target_name","text":"target_name(p::Pipeline{name}) where name = name\n\nGet the target symbol(s).\n\n\n\n\n\n","category":"method"}]
}
