# ConvergencePlots.jl

A Julia package for live tracking of the convergence of your algorithm. The
plotting is delegated to a backend of your choice: [PythonPlot.jl](https://github.com/JuliaPy/PythonPlot.jl)
(the default), [Plots.jl](https://github.com/JuliaPlots/Plots.jl), or
[Makie.jl](https://github.com/MakieOrg/Makie.jl). The backends are implemented
as package extensions, so you only load (and pay for) the plotting package
you use. ConvergencePlots is used by the Nonconvex ecosystem to trace
optimizer convergence.

## Installation

```julia
using Pkg
pkg"add ConvergencePlots"
```

The package does not depend on any plotting package by default. Load the
plotting package of your choice before constructing a plot, e.g. `using
PythonPlot`, `using Plots`, or `using Makie` (together with a Makie backend such
as `CairoMakie` or `GLMakie`).

## Usage

First create an empty plot:

```julia
using ConvergencePlots, PythonPlot

plot = ConvergencePlot()
```

The default backend is the `PythonPlot` backend if `PythonPlot` is loaded, otherwise
the `Plots` backend if `Plots` is loaded, otherwise the `Makie` backend if
`Makie` is loaded. To choose a backend explicitly, pass the `backend`
keyword argument:

```julia
plot = ConvergencePlot(backend = ConvergencePlots.plotsbackend())
```

This will create an empty convergence plot that plots up to 100000 history
points. Older points are overwritten. To specify how many history points to
plot, use the constructor:

```julia
plot = ConvergencePlot(n)
```

where `n` is the number of points.

The keyword arguments you can pass to the `ConvergencePlot` constructor are:

- `names`: a `Vector{String}` that has all the names of the convergence
  metrics to be plotted. The default value of `names` is `["Residual"]`.

- `options`: a dictionary mapping each name in `names` to a `NamedTuple`.
  Each named tuple has the plotting options to pass to the plotting backend,
  e.g. `(label = "KKT residual", ls = "--", marker = "+")` for the `PythonPlot`
  backend. If `label` is not passed, it defaults to the corresponding name in
  `names`. You can also pass a single `NamedTuple` of options without the
  `label` option, and it will be used for all the names. The default colors
  are generated deterministically using the golden angle hue sequence, so
  each curve gets a distinct color.

- `show`: if `true` the empty figure will be displayed. This is `false` by
  default.

- `figsize`: the `(width, height)` of the figure. The unit is backend
  dependent: inches for `PythonPlot`; for `Plots` and `Makie` the value is scaled
  by a factor of 100 and interpreted as pixels.

After creating an empty plot, you can add points to it as follows:

```julia
addpoint!(plot, Dict("Residual" => 1.0))
```

where the second argument can contain one value for each name in `names`. If
only a single name exists, you can also use:

```julia
addpoint!(plot, 1.0)
```

Adding a point will display the plot by default. To stop the plot from
displaying, set the `show` keyword argument to `false`.

To add a whole batch of points at once, use `addpoints!`:

```julia
addpoints!(plot, Dict("Residual" => [1.0, 2.0, 3.0]))
```

By default, `addpoints!` does not update the plot. To update the plot after
adding the batch, set the `update` keyword argument to `true`. Similarly,
`addpoint!` accepts the `update` keyword argument: setting it to `false`
updates the history without redrawing the plot, which can be useful to avoid
plotting overhead inside a hot loop.

To save the current figure to a file, call `updateplot!` with the `filename`
keyword argument:

```julia
updateplot!(plot; show = false, filename = "convergence.png")
```

To close the plot, call:

```julia
closeplot!(plot)
```

## Example

```julia
using ConvergencePlots, PythonPlot

plot = ConvergencePlot(
    names = ["KKT residual", "|Δx|", "|Δf|"],
    options = Dict(
        "KKT residual" => (color = "red",),
        "|Δx|" => (color = "blue",),
        "|Δf|" => (color = "black",),
    ),
)
kkt = 1 ./ (1:50)
Δx = 0.1 .* sqrt.(kkt)
Δf = 10 .* kkt .^ 2
for i in 1:50
    sleep(1e-4)
    addpoint!(
        plot,
        Dict(
            "KKT residual" => kkt[i],
            "|Δx|" => Δx[i],
            "|Δf|" => Δf[i],
        ),
    )
end
```
