# NEWS

## Unreleased

- Aligned the repository with the JuliaNonconvex ecosystem conventions:
  multi-OS CI with code coverage, updated TagBot workflow, compat bounds for
  all dependencies, a `julia = "1.10"` requirement, and a modular `src`
  layout.
- Added `addpoints!` for batch insertion of history points, the `figsize`
  constructor keyword argument, `filename` saving in `updateplot!`, and the
  `update` keyword argument for lazy plotting.
- Added a test suite covering the plot lifecycle, history bookkeeping, and
  plotting options.
- Fixed default color generation to draw all random numbers from the package
  RNG instead of the global RNG.
- Fixed `options` dictionaries with missing entries or explicit labels.
- Added docstrings for the exported API.
