"""
    ConvergencePlot{B}

A live convergence plot that keeps track of the history of one or more
convergence metrics. Points are added with [`addpoint!`](@ref) or
[`addpoints!`](@ref), and the plot is (re)drawn with [`updateplot!`](@ref).
The plotting is delegated to a backend of type `B <: AbstractPlotBackend`
provided by a package extension; see [`AbstractPlotBackend`](@ref).
"""
mutable struct ConvergencePlot{B<:AbstractPlotBackend}
    backend::B
    names::Vector{String}
    history::Dict{String,Vector{Float64}}
    options::Dict{String,NamedTuple}
    npoints::Int
    figsize::Tuple{Int,Int}
end

"""
    ConvergencePlot(
        npoints::Int = 100000;
        backend = default_backend(),
        names = ["Residual"],
        options = nothing,
        show = false,
        figsize = (20, 10),
    )

Create an empty convergence plot that keeps the last `npoints` history points
for every metric in `names`. Older points are overwritten. A plotting package
must be loaded for the default backend to be available, see
[`default_backend`](@ref).

# Keyword arguments

- `backend`: the plotting backend, e.g. [`pyplotbackend`](@ref),
  [`plotsbackend`](@ref) or [`makiebackend`](@ref). The default is
  [`default_backend`](@ref).
- `names`: a `Vector{String}` of the convergence metrics to plot. The default
  value is `["Residual"]`.
- `options`: a dictionary mapping each name in `names` to a `NamedTuple` of
  plotting options to pass to the backend, e.g. `(label = "KKT residual",
  ls = "--", marker = "+")` for the `PyPlot` backend. If `label` is not
  passed, it defaults to the corresponding name in `names`. A single
  `NamedTuple` of options without the `label` option can also be passed, and
  it will be used for all the names.
- `show`: if `true` the empty figure will be displayed. This is `false` by
  default.
- `figsize`: the `(width, height)` of the figure. The unit is backend
  dependent: inches for `PyPlot`; for `Plots` and `Makie` the value is
  scaled by a factor of 100 and interpreted as pixels.
"""
function ConvergencePlot(
    npoints::Int = 100000;
    backend = default_backend(),
    names = ["Residual"],
    options = nothing,
    show = false,
    figsize = (20, 10),
)
    history = Dict(n => Float64[] for n in names)
    options = getoptions(names, options)
    @assert keys(history) == keys(options)
    _initialize!(backend, length(names), figsize)
    plot = ConvergencePlot(backend, names, history, options, npoints, figsize)
    show && _show!(backend)
    return plot
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
    @assert length(plot.history) == 1
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
            # The history may not yet be at capacity; shrink it to `keep`
            # before appending the batch so the last `npoints` points survive
            # (writing `len` elements into `h[keep+1:end]` raised a
            # DimensionMismatch whenever `length(h) < npoints`).
            resize!(h, keep)
            append!(h, yk)
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
    @unpack backend, names, history, options = plot
    _clear!(backend)
    for (i, n) in enumerate(names)
        h = history[n]
        isempty(h) && continue
        _plotseries!(backend, i, 1:length(h), h; options[n]...)
    end
    _decorate!(backend, names, options)
    show && _show!(backend)
    filename !== nothing && _save!(backend, filename)
    return plot
end

"""
    closeplot!(plot::ConvergencePlot)

Close the figure of `plot` and replace it with a new empty one.
"""
function closeplot!(plot::ConvergencePlot)
    _close!(plot.backend)
    _initialize!(plot.backend, length(plot.names), plot.figsize)
    return plot
end
