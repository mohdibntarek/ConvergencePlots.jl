module ConvergencePlotsPyPlotExt

using ConvergencePlots, PyPlot
using Colors: RGB
import ConvergencePlots: AbstractPlotBackend,
    _initialize!, _clear!, _plotseries!, _decorate!, _show!, _save!, _close!

"""
    PyPlotBackend

Plotting backend based on `PyPlot` (matplotlib). Curves are drawn in stacked
subplots with each pair of curves sharing an x-axis through matplotlib twin
axes.
"""
mutable struct PyPlotBackend <: AbstractPlotBackend
    fig::Any
    axs::Vector{Any}
end

pyplot_backend() = PyPlotBackend(nothing, Any[])

function _initialize!(b::PyPlotBackend, ncurves, figsize)
    b.fig, b.axs = emptyplot(ncurves, figsize)
    return b
end

function _clear!(b::PyPlotBackend)
    keepinteractive() do
        for ax in b.axs
            ax.clear()
        end
    end
    return b
end

function _plotseries!(b::PyPlotBackend, i, x, y; color = nothing, kwargs...)
    ax = b.axs[i]
    ax.plot(x, y; color = pycolor(color), kwargs...)
    return b
end

function _decorate!(b::PyPlotBackend, names, options)
    keepinteractive() do
        for (i, n) in enumerate(names)
            ax = b.axs[i]
            if mod(i, 2) == 1
                ax.set_xlabel("Iteration")
            end
            ax.set_ylabel(n)
            ax.tick_params(axis = "y", labelcolor = pycolor(options[n].color))
        end
        b.fig.canvas.draw()
        b.fig.legend(loc = 2)
    end
    return b
end

function _show!(b::PyPlotBackend)
    keepinteractive() do
        # Display the backend's own figure instead of the global
        # PyPlot.show(), which shows all figures (or gcf()).
        if PyPlot.hasproperty(b.fig, :show)
            PyPlot.pycall(b.fig."show", PyPlot.PyObject)
        else
            # Fallback for very old matplotlib versions without Figure.show.
            PyPlot.show(block = false)
        end
    end
    return b
end

function _save!(b::PyPlotBackend, filename)
    b.fig.savefig(filename)
    return b
end

function _close!(b::PyPlotBackend)
    PyPlot.close(b.fig)
    return b
end

# matplotlib accepts strings and RGB tuples but not Colors.jl colorants.
function pycolor(c)
    c isa AbstractString && return c
    c isa Symbol && return String(c)
    rgb = try
        convert(RGB{Float64}, c)
    catch
        return c
    end
    return (rgb.r, rgb.g, rgb.b)
end

function emptyplot(ncurves, figsize)
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
    try
        f()
    finally
        was_interactive && PyPlot.ion()
    end
end

end
