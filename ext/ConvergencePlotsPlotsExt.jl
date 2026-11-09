module ConvergencePlotsPlotsExt

using ConvergencePlots, Plots
import ConvergencePlots: AbstractPlotBackend,
    _initialize!, _clear!, _plotseries!, _decorate!, _show!, _save!, _close!

"""
    PlotsBackend

Plotting backend based on `Plots` (any Plots backend such as `gr` or
`pyplot`). Curves are drawn in stacked subplots sharing an x-axis.
"""
mutable struct PlotsBackend <: AbstractPlotBackend
    obj::Any
    ncurves::Int
    figsize::Tuple{Int,Int}
end

plots_backend() = PlotsBackend(nothing, 0, (20, 10))

function _initialize!(b::PlotsBackend, ncurves, figsize)
    b.ncurves = ncurves
    b.figsize = figsize
    b.obj = freshplot(b)
    return b
end

function _clear!(b::PlotsBackend)
    b.obj = freshplot(b)
    return b
end

function _plotseries!(b::PlotsBackend, i, x, y; kwargs...)
    Plots.plot!(b.obj, subplot = i, x, y; kwargs...)
    return b
end

function _decorate!(b::PlotsBackend, names, options)
    for (i, n) in enumerate(names)
        Plots.ylabel!(b.obj[i], n)
    end
    Plots.xlabel!(b.obj[end], "Iteration")
    return b
end

function _show!(b::PlotsBackend)
    if hasmethod(Base.display, Tuple{typeof(b.obj)})
        Base.display(b.obj)
    end
    return b
end

function _save!(b::PlotsBackend, filename)
    Plots.savefig(b.obj, filename)
    return b
end

function _close!(b::PlotsBackend)
    b.obj = nothing
    return b
end

function freshplot(b::PlotsBackend)
    Plots.plot(
        layout = (b.ncurves, 1),
        link = :x,
        legend = :topright,
        size = b.figsize .* 100,
        margin = 5Plots.mm,
        minorgrid = true,
    )
end

end
