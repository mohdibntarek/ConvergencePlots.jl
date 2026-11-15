# NEWS

## 0.3.0

- **Breaking (changelog)**: the matplotlib backend is now provided by
  [PythonPlot.jl](https://github.com/JuliaPy/PythonPlot.jl) (matplotlib
  through [PythonCall.jl](https://github.com/JuliaPy/PythonCall.jl)) instead
  of PyPlot.jl/PyCall. Load `PythonPlot` (e.g. `using PythonPlot`) to get the
  default backend; `pyplotbackend()` returns the new `PythonPlotBackend`.
  This fixes the recurring `PyCall not properly installed` CI failures on
  updated runner images: PythonCall manages its Python environment through
  CondaPkg and needs no preconfigured Python.
- The `ConvergencePlotsPyPlotExt` extension is renamed to
  `ConvergencePlotsPythonPlotExt`.
- Added a Documenter documentation site (`docs/`) with a `Documentation`
  CI workflow, and docstrings for `plotsbackend`/`makiebackend`.

## 0.2.2

- The PyPlot backend no longer stacks a new figure legend on every
  `updateplot!` (the previous legend is removed first).

## 0.2.1

- Fixed the backend state reuse and figure lifecycle bugs (plots, legends
  and history no longer leak across figures).
- Hardened CI against a poisoned Conda depot cache.

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
