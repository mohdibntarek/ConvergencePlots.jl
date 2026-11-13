# Headless rendering: force GR to render without a display.
ENV["GKSwstype"] = "100"

using ConvergencePlots, Test
using Plots
using CairoMakie

const PlotsExt = Base.get_extension(ConvergencePlots, :ConvergencePlotsPlotsExt)
const MakieExt = Base.get_extension(ConvergencePlots, :ConvergencePlotsMakieExt)

@testset "default backend" begin
    # PyPlot is not loaded in this process, Plots is loaded before Makie, so
    # the default backend is the Plots backend.
    @test ConvergencePlots.default_backend() isa PlotsExt.PlotsBackend
    @test ConvergencePlots.plotsbackend() isa PlotsExt.PlotsBackend
    @test ConvergencePlots.makiebackend() isa MakieExt.MakieBackend
    @test_throws ArgumentError ConvergencePlots.pyplotbackend()
end

function test_backend(plot)
    addpoint!(plot, Dict("A" => 1.0, "B" => 2.0); show = false)
    addpoints!(plot, Dict("A" => [2.0, 3.0], "B" => [4.0, 6.0]); show = false)
    @test plot.history["A"] == [1.0, 2.0, 3.0]
    @test plot.history["B"] == [2.0, 4.0, 6.0]
    mktempdir() do dir
        filename = joinpath(dir, "fig.png")
        updateplot!(plot; show = false, filename = filename)
        @test isfile(filename)
    end
    closeplot!(plot)
end

@testset "Plots backend" begin
    plot = ConvergencePlot(
        backend = ConvergencePlots.plotsbackend(),
        names = ["A", "B"],
    )
    test_backend(plot)

    # Constructor default with the Plots backend loaded.
    plot = ConvergencePlot(names = ["A", "B"])
    @test plot.backend isa PlotsExt.PlotsBackend
    test_backend(plot)

    # figsize is scaled by a factor of 100 and used as the pixel size.
    plot = ConvergencePlot(
        backend = ConvergencePlots.plotsbackend(),
        figsize = (5, 3),
    )
    @test plot.backend.obj[:size] == (500, 300)
    closeplot!(plot)
end

@testset "Makie backend" begin
    plot = ConvergencePlot(
        backend = ConvergencePlots.makiebackend(),
        names = ["A", "B"],
    )
    test_backend(plot)

    # _show! is a no-op under CairoMakie (figures have no display method).
    plot = ConvergencePlot(
        backend = ConvergencePlots.makiebackend(),
        names = ["A", "B"],
    )
    @test ConvergencePlots._show!(plot.backend) === plot.backend
    test_backend(plot)

    # Reusing a backend for a second ConvergencePlot must not leak plots,
    # labels, or a legend bound to the previous figure.
    backend = ConvergencePlots.makiebackend()
    plot = ConvergencePlot(backend = backend, names = ["A", "B"])
    addpoint!(plot, Dict("A" => 1.0, "B" => 2.0); show = false)
    @test length(backend.plots) == 2
    @test backend.labels == ["A", "B"]
    @test backend.legend !== nothing
    oldfig = backend.fig
    plot = ConvergencePlot(backend = backend, names = ["C"])
    @test backend.fig !== oldfig
    @test isempty(backend.plots)
    @test isempty(backend.labels)
    @test backend.legend === nothing
    # The reused backend is usable: a fresh legend is bound to the new figure.
    addpoint!(plot, 1.0; show = false)
    @test length(backend.plots) == 1
    @test backend.labels == ["C"]
    @test backend.legend !== nothing
    @test backend.legend.parent === backend.fig
    closeplot!(plot)

    # _close! drops the figure and resets the state. It is a no-op for
    # figures without a screen (CairoMakie) and can be called twice.
    backend = ConvergencePlots.makiebackend()
    ConvergencePlots._initialize!(backend, 1, (5, 3))
    @test ConvergencePlots._close!(backend) === backend
    @test backend.fig === nothing
    @test isempty(backend.axes)
    @test backend.legend === nothing
    @test isempty(backend.plots)
    @test isempty(backend.labels)
    @test ConvergencePlots._close!(backend) === backend

    # figsize is scaled by a factor of 100 and used as the pixel size.
    plot = ConvergencePlot(
        backend = ConvergencePlots.makiebackend(),
        figsize = (5, 3),
    )
    @test size(plot.backend.fig.scene) == (500, 300)
    closeplot!(plot)
end
