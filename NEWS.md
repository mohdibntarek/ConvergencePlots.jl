# NEWS

## 0.2.0

- **Breaking**: plotting backends are now implemented as package extensions.
  `PyPlot`, `Plots`, and `Makie` are weak dependencies and no plotting package
  is loaded by default. Load one of them (e.g. `using PyPlot`) before
  constructing a `ConvergencePlot`, or pass the `backend` keyword argument
  (`pyplotbackend()`, `plotsbackend()`, or `makiebackend()`). The default
  backend is `PyPlot` if it is loaded, then `Plots`, then `Makie`.
- Added `addpoints!` for batch insertion of history points, the `figsize`
  constructor keyword argument, `filename` saving in `updateplot!`, and the
  `update` keyword argument for lazy plotting.
- Default colors are now generated deterministically with the golden angle
  hue sequence (using Colors.jl) instead of a seeded random generator, so
  every curve gets a distinct default color.
- Aligned the repository with the JuliaNonconvex ecosystem conventions:
  multi-OS CI with code coverage, backend extension integration tests,
  updated TagBot workflow, compat bounds for all dependencies, a
  `julia = "1.10"` requirement, and a modular `src` layout.
- Added a test suite covering the plot lifecycle, history bookkeeping, and
  plotting options.
- Fixed `options` dictionaries with missing entries or explicit labels.
- Added docstrings for the exported API.
