"""
    AbstractPlotBackend

Abstract supertype of the plotting backends supported by ConvergencePlots.
Each backend is provided by a package extension that is automatically loaded
when the corresponding plotting package is loaded:

- `ConvergencePlotsPythonPlotExt` for `PythonPlot` (the default backend),
- `ConvergencePlotsPlotsExt` for `Plots`,
- `ConvergencePlotsMakieExt` for `Makie`.

Use [`pyplotbackend`](@ref), [`plotsbackend`](@ref), [`makiebackend`](@ref)
or [`default_backend`](@ref) to get a backend instance.
"""
abstract type AbstractPlotBackend end

"""
    default_backend()

Return the default plotting backend: the `PythonPlot` backend if `PythonPlot`
is loaded, otherwise the `Plots` backend if `Plots` is loaded, otherwise the
`Makie` backend if `Makie` is loaded. An `ArgumentError` is thrown if none of
these plotting packages is loaded.
"""
function default_backend()
    if (ext = Base.get_extension(@__MODULE__, :ConvergencePlotsPythonPlotExt)) !== nothing
        return ext.pyplot_backend()
    elseif (ext = Base.get_extension(@__MODULE__, :ConvergencePlotsPlotsExt)) !== nothing
        return ext.plots_backend()
    elseif (ext = Base.get_extension(@__MODULE__, :ConvergencePlotsMakieExt)) !== nothing
        return ext.makie_backend()
    else
        throw(ArgumentError(
            "no plotting backend is loaded; load one of `PythonPlot`, `Plots`, or " *
            "`Makie` (e.g. `using PythonPlot`) before constructing a " *
            "`ConvergencePlot`, or pass the `backend` keyword argument " *
            "explicitly",
        ))
    end
end

"""
    pyplotbackend()
    plotsbackend()
    makiebackend()

Return the plotting backend of the corresponding package. The package must be
loaded first, e.g. with `using PythonPlot`, `using Plots`, or `using Makie`.
"""
function pyplotbackend()
    return _getbackend(:ConvergencePlotsPythonPlotExt, :pyplot_backend, "PythonPlot")
end
function plotsbackend()
    return _getbackend(:ConvergencePlotsPlotsExt, :plots_backend, "Plots")
end
function makiebackend()
    return _getbackend(:ConvergencePlotsMakieExt, :makie_backend, "Makie")
end
@doc """
    plotsbackend()

Return the `Plots` plotting backend. `Plots` must be loaded first, e.g. with
`using Plots`. See also [`pyplotbackend`](@ref) and [`makiebackend`](@ref).
""" plotsbackend
@doc """
    makiebackend()

Return the `Makie` plotting backend. `Makie` must be loaded first, e.g. with
`using Makie` (together with a backend such as `CairoMakie` or `GLMakie`).
See also [`pyplotbackend`](@ref) and [`plotsbackend`](@ref).
""" makiebackend

function _getbackend(extname::Symbol, f::Symbol, pkg::String)
    ext = Base.get_extension(@__MODULE__, extname)
    ext === nothing && throw(ArgumentError(
        "the $pkg plotting backend is not loaded; run `using $pkg` before " *
        "requesting it",
    ))
    return getproperty(ext, f)()
end

# Backend interface. Each backend extension implements the functions below for
# its concrete backend type. The core package only calls them through
# `AbstractPlotBackend`-typed dispatch.

"""
    _initialize!(backend::AbstractPlotBackend, ncurves::Int, figsize)

Create the figure of `backend` for `ncurves` curves. This is called when a
`ConvergencePlot` is constructed and by `closeplot!`.
"""
_initialize!(backend::AbstractPlotBackend, ncurves, figsize) =
    error("_initialize! is not implemented for $(typeof(backend))")

"""
    _clear!(backend::AbstractPlotBackend)

Clear the figure of `backend` in preparation for a fresh redraw.
"""
_clear!(backend::AbstractPlotBackend) = nothing

"""
    _plotseries!(backend::AbstractPlotBackend, i::Int, x, y; kwargs...)

Plot curve `i` with x-coordinates `x` and y-coordinates `y`. `kwargs` contains
at least `label` and `color` as well as any backend-specific options passed by
the user through the `options` constructor keyword argument.
"""
_plotseries!(backend::AbstractPlotBackend, i, x, y; kwargs...) =
    error("_plotseries! is not implemented for $(typeof(backend))")

"""
    _decorate!(backend::AbstractPlotBackend, names, options)

Add axis labels, legends, and any other decorations to the figure of
`backend`. `names` is the vector of curve names and `options` maps each name
to its plotting options `NamedTuple`.
"""
_decorate!(backend::AbstractPlotBackend, names, options) = nothing

"""
    _show!(backend::AbstractPlotBackend)

Display the figure of `backend` without blocking where possible.
"""
_show!(backend::AbstractPlotBackend) = nothing

"""
    _save!(backend::AbstractPlotBackend, filename::AbstractString)

Save the figure of `backend` to the file `filename`.
"""
_save!(backend::AbstractPlotBackend, filename) =
    error("_save! is not implemented for $(typeof(backend))")

"""
    _close!(backend::AbstractPlotBackend)

Close the figure of `backend`. A new figure can be created afterwards with
[`_initialize!`](@ref).
"""
_close!(backend::AbstractPlotBackend) = nothing
