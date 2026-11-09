module ConvergencePlotsMakieExt

using ConvergencePlots, Makie
import ConvergencePlots: AbstractPlotBackend,
    _initialize!, _clear!, _plotseries!, _decorate!, _show!, _save!, _close!

"""
    MakieBackend

Plotting backend based on `Makie` (any Makie backend such as `GLMakie` for
live windows or `CairoMakie` for static rendering). Curves are drawn in
stacked axes sharing an x-axis.
"""
mutable struct MakieBackend <: AbstractPlotBackend
    fig::Any
    axes::Vector{Any}
    legend::Any
    plots::Vector{Any}
    labels::Vector{String}
    ncurves::Int
    figsize::Tuple{Int,Int}
end

makie_backend() = MakieBackend(nothing, Any[], nothing, Any[], String[], 0, (20, 10))

function _initialize!(b::MakieBackend, ncurves, figsize)
    b.ncurves = ncurves
    b.figsize = figsize
    b.fig, b.axes = makiefigure(ncurves, figsize)
    return b
end

function _clear!(b::MakieBackend)
    for ax in b.axes
        Makie.empty!(ax)
    end
    empty!(b.plots)
    empty!(b.labels)
    return b
end

function _plotseries!(b::MakieBackend, i, x, y; label = "", kwargs...)
    p = Makie.lines!(b.axes[i], x, y; label = label, kwargs...)
    push!(b.plots, p)
    push!(b.labels, string(label))
    return b
end

function _decorate!(b::MakieBackend, names, options)
    for (i, n) in enumerate(names)
        b.axes[i].ylabel = n
    end
    b.axes[end].xlabel = "Iteration"
    # Rebuild the legend with the currently labeled plots.
    if b.legend !== nothing
        Makie.delete!(b.legend)
        b.legend = nothing
    end
    if !isempty(b.plots)
        b.legend = Makie.Legend(b.fig[1, 2], b.plots, b.labels)
    end
    return b
end

function _show!(b::MakieBackend)
    if hasmethod(Makie.display, Tuple{typeof(b.fig)})
        Makie.display(b.fig)
    end
    return b
end

function _save!(b::MakieBackend, filename)
    Makie.save(filename, b.fig)
    return b
end

function _close!(b::MakieBackend)
    b.fig = nothing
    b.axes = Any[]
    b.legend = nothing
    empty!(b.plots)
    empty!(b.labels)
    return b
end

function makiefigure(ncurves, figsize)
    fig = Makie.Figure(size = figsize .* 100)
    axes = [Makie.Axis(fig[i, 1]) for i in 1:ncurves]
    for i in 2:ncurves
        Makie.linkxaxes!(axes[1], axes[i])
    end
    for i in 1:(ncurves - 1)
        Makie.hidexdecorations!(axes[i]; ticks = false, ticklabels = false, grid = false)
    end
    return fig, axes
end

end
