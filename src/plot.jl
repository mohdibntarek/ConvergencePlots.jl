"""
    ConvergencePlot

A live convergence plot that keeps track of the history of one or more
convergence metrics. Points are added with [`addpoint!`](@ref) or
[`addpoints!`](@ref), and the plot is (re)drawn with [`updateplot!`](@ref).
"""
mutable struct ConvergencePlot
    fig
    axs
    names::Vector{String}
    history::Dict
    options::Dict
    npoints::Int
    figsize::Tuple{Int,Int}
end

"""
    ConvergencePlot(
        npoints::Int = 100000;
        names = ["Residual"],
        options = nothing,
        show = false,
        figsize = (20, 10),
    )

Create an empty convergence plot that keeps the last `npoints` history points
for every metric in `names`. Older points are overwritten.

# Keyword arguments

- `names`: a `Vector{String}` of the convergence metrics to plot. The default
  value is `["Residual"]`.
- `options`: a dictionary mapping each name in `names` to a `NamedTuple` of
  plotting options to pass to `PyPlot`, e.g. `(label = "KKT residual",
  ls = "--", marker = "+")`. If `label` is not passed, it defaults to the
  corresponding name in `names`. A single `NamedTuple` of options without the
  `label` option can also be passed, and it will be used for all the names.
- `show`: if `true` the empty figure will be displayed. This is `false` by
  default.
- `figsize`: the `(width, height)` of the figure in inches, passed to
  `PyPlot.subplots`.
"""
function ConvergencePlot(
    npoints::Int = 100000;
    names = ["Residual"],
    options = nothing,
    show = false,
    figsize = (20, 10),
)
    history = Dict(n => Float64[] for n in names)
    options = getoptions(names, options)
    @assert keys(history) == keys(options)
    fig, axs = emptyplot(length(names), figsize = figsize)
    if show
        PyPlot.show(block = false)
    end
    return ConvergencePlot(fig, axs, names, history, options, npoints, figsize)
end

"""
    addpoint!(plot::ConvergencePlot, y::Real; kwargs...)
    addpoint!(plot::ConvergencePlot, y::Dict; update = true, kwargs...)

Add a single point to the history of `plot` and update the plot.

The second argument can be a single value, in which case `plot` must have
exactly one name, or a dictionary containing one value for each name in
`plot.names`. Adding a point displays the plot by default; set the `show`
keyword argument to `false` to stop the plot from being displayed. If `update`
is `false`, the history is updated without redrawing the plot. All other
keyword arguments are forwarded to [`updateplot!`](@ref).
"""
function addpoint!(plot::ConvergencePlot, y::Real; kwargs...)
    @assert length(keys(plot.history)) == 1
    k = first(keys(plot.history))
    return addpoint!(plot, Dict(k => y); kwargs...)
end
function addpoint!(plot::ConvergencePlot, y::Dict; update = true, kwargs...)
    @unpack history, npoints = plot
    @assert all(k -> haskey(history, k), keys(y))
    for k in keys(y)
        if length(history[k]) < npoints
            push!(history[k], y[k])
        else
            history[k][1:npoints-1] .= history[k][2:npoints]
            history[k][npoints] = y[k]
        end
    end
    update && updateplot!(plot; kwargs...)
    return plot
end

"""
    addpoints!(plot::ConvergencePlot, y::Dict; update = false, kwargs...)

Add a batch of points to the history of `plot`. The dictionary `y` maps each
name in `plot.names` to a vector of points. If a batch is longer than
`plot.npoints`, only the last `plot.npoints` points are kept. By default the
plot is not updated after inserting the points; set `update` to `true` to
redraw it, in which case all other keyword arguments are forwarded to
[`updateplot!`](@ref).
"""
function addpoints!(plot::ConvergencePlot, y::Dict; update = false, kwargs...)
    @unpack history, npoints = plot
    @assert all(k -> haskey(history, k), keys(y))
    for k in keys(y)
        yk = collect(y[k])
        len = length(yk)
        h = history[k]
        if len >= npoints
            empty!(h)
            append!(h, yk[end-npoints+1:end])
        elseif length(h) + len <= npoints
            append!(h, yk)
        else
            keep = npoints - len
            h[1:keep] = h[end-keep+1:end]
            h[keep+1:end] = yk
        end
    end
    update && updateplot!(plot; kwargs...)
    return plot
end

"""
    updateplot!(plot::ConvergencePlot; show = true, filename = nothing)

Redraw the plot with the current history of `plot`. If `show` is `true`, the
figure is displayed. If `filename` is not `nothing`, the figure is saved to
that file.
"""
function updateplot!(plot::ConvergencePlot; show = true, filename = nothing)
    @unpack fig, axs, names, history, options = plot
    keepinteractive() do
        for ax in axs
            ax.clear()
        end
        for i in 1:length(names)
            ax = axs[i]
            n = names[i]
            ax.plot(1:length(history[n]), history[n]; options[n]...)
            if mod(i, 2) == 1
                ax.set_xlabel("Iteration")
            end
            ax.set_ylabel(n)
            ax.tick_params(axis = "y", labelcolor = options[n].color)
        end
        fig.canvas.draw()
        fig.legend(loc = 2)
        if show
            PyPlot.show(block = false)
        end
    end
    filename !== nothing && fig.savefig(filename)
    return plot
end

"""
    closeplot!(plot::ConvergencePlot)

Close the figure of `plot` and replace it with a new empty one.
"""
function closeplot!(plot::ConvergencePlot)
    PyPlot.close(plot.fig)
    fig, axs = emptyplot(length(plot.names), figsize = plot.figsize)
    @pack! plot = fig, axs
    return plot
end

function emptyplot(ncurves; figsize = (20, 10))
    if ncurves % 2 == 0
        nsubplots = (ncurves ÷ 2)
    else
        nsubplots = (ncurves ÷ 2) + 1
    end
    local fig, axs
    keepinteractive() do
        fig, axs1 = PyPlot.subplots(nsubplots, figsize = figsize)
        axs = []
        for i in 1:nsubplots
            ax1 = nsubplots == 1 ? axs1 : axs1[i]
            push!(axs, ax1)
            if 2i <= ncurves
                ax2 = ax1.twinx()
                push!(axs, ax2)
            end
        end
    end
    return fig, axs
end

function keepinteractive(f)
    was_interactive = PyPlot.isinteractive()
    was_interactive && PyPlot.ioff()
    f()
    was_interactive && PyPlot.ion()
end
