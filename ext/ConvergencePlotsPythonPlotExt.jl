module ConvergencePlotsPythonPlotExt

using ConvergencePlots, PythonPlot
using Colors: RGB
import ConvergencePlots: AbstractPlotBackend,
    _initialize!, _clear!, _plotseries!, _decorate!, _show!, _save!, _close!

"""
    PythonPlotBackend

Plotting backend based on `PythonPlot` (matplotlib through
[PythonCall](https://github.com/JuliaPy/PythonCall.jl)). Curves are drawn in
stacked subplots with each pair of curves sharing an x-axis through
matplotlib twin axes.
"""
mutable struct PythonPlotBackend <: AbstractPlotBackend
    fig::Any
    axs::Vector{Any}
    legend::Any
end

pyplot_backend() = PythonPlotBackend(nothing, Any[], nothing)

function _initialize!(b::PythonPlotBackend, ncurves, figsize)
    b.fig, b.axs = emptyplot(ncurves, figsize)
    # The old legend belongs to the previous figure and must not leak into
    # the new one.
    b.legend = nothing
    return b
end

function _clear!(b::PythonPlotBackend)
    keepinteractive() do
        for ax in b.axs
            ax.clear()
        end
    end
    return b
end

function _plotseries!(b::PythonPlotBackend, i, x, y; color = nothing, kwargs...)
    ax = b.axs[i]
    ax.plot(x, y; color = pycolor(color), kwargs...)
    return b
end

function _decorate!(b::PythonPlotBackend, names, options)
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
        # Remove the previous figure legend before creating a new one, so
        # repeated `updateplot!` calls do not stack legends.
        if b.legend !== nothing
            b.legend.remove()
            b.legend = nothing
        end
        b.legend = b.fig.legend(loc = 2)
    end
    return b
end

function _show!(b::PythonPlotBackend)
    keepinteractive() do
        # Display the backend's own figure instead of PythonPlot.show(),
        # which shows all figures (or gcf()).
        if PythonPlot.hasproperty(b.fig, :show)
            b.fig.show()
        else
            # Fallback for very old matplotlib versions without Figure.show.
            PythonPlot.show(block = false)
        end
    end
    return b
end

function _save!(b::PythonPlotBackend, filename)
    b.fig.savefig(filename)
    return b
end

function _close!(b::PythonPlotBackend)
    PythonPlot.pyplot.close(b.fig)
    b.fig = nothing
    b.axs = Any[]
    b.legend = nothing
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
        fig, axs1 = PythonPlot.subplots(nsubplots, figsize = figsize)
        axs = []
        for i in 1:nsubplots
            # PythonCall's generic `Py` indexing is 0-based, unlike the
            # PyCall `PyObject` indexing this code used before the switch.
            ax1 = nsubplots == 1 ? axs1 : axs1[i - 1]
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
    was_interactive = PythonPlot.pyconvert(Bool, PythonPlot.isinteractive())
    was_interactive && PythonPlot.ioff()
    try
        f()
    finally
        was_interactive && PythonPlot.ion()
    end
end

end
