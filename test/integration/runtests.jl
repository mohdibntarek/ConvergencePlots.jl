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
end
