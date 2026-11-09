# Use a headless matplotlib backend so the tests run without a display.
ENV["MPLBACKEND"] = "agg"

using ConvergencePlots, Test
using Colors: RGB
using PyPlot

const PyPlotExt = Base.get_extension(ConvergencePlots, :ConvergencePlotsPyPlotExt)

@testset "no backend loaded" begin
    # In a fresh process that only loads ConvergencePlots, no backend is
    # available and the default backend errors.
    code = """
    using ConvergencePlots
    err = try
        ConvergencePlot()
        nothing
    catch e
        e
    end
    @assert err isa ArgumentError
    @assert occursin("backend", sprint(showerror, err))
    """
    cmd = `$(Base.julia_cmd()) --startup-file=no --project=$(Base.active_project()) -e $code`
    @test success(run(cmd))
end

@testset "default backend" begin
    @test ConvergencePlots.default_backend() isa PyPlotExt.PyPlotBackend
    @test ConvergencePlots.pyplotbackend() isa PyPlotExt.PyPlotBackend
    @test_throws ArgumentError ConvergencePlots.plotsbackend()
    @test_throws ArgumentError ConvergencePlots.makiebackend()
end

@testset "ConvergencePlot constructor" begin
    plot = ConvergencePlot()
    @test plot.names == ["Residual"]
    @test plot.npoints == 100000
    @test plot.figsize == (20, 10)
    @test isempty(plot.history["Residual"])
    @test plot.options["Residual"].label == "Residual"
    @test plot.options["Residual"].color isa RGB
    @test plot.backend isa PyPlotExt.PyPlotBackend
    closeplot!(plot)
    PyPlot.close(plot.backend.fig)

    plot = ConvergencePlot(10)
    @test plot.npoints == 10
    closeplot!(plot)
    PyPlot.close(plot.backend.fig)

    plot = ConvergencePlot(
        backend = ConvergencePlots.pyplotbackend(),
        names = ["A", "B"],
        options = Dict("A" => (ls = "--",), "B" => (ls = ":",)),
        figsize = (5, 3),
    )
    @test plot.names == ["A", "B"]
    @test plot.figsize == (5, 3)
    @test length(plot.backend.axs) == 2
    @test isempty(plot.history["A"])
    @test isempty(plot.history["B"])
    @test plot.options["A"].label == "A"
    @test plot.options["A"].ls == "--"
    @test plot.options["B"].label == "B"
    @test plot.options["B"].ls == ":"
    closeplot!(plot)
    PyPlot.close(plot.backend.fig)
end

@testset "addpoint!" begin
    # The history keeps only the last npoints points.
    plot = ConvergencePlot(3)
    for i in 1:5
        addpoint!(plot, Float64(i); show = false)
    end
    @test plot.history["Residual"] == [3.0, 4.0, 5.0]
    closeplot!(plot)
    PyPlot.close(plot.backend.fig)

    # Multiple metrics.
    plot = ConvergencePlot(3, names = ["A", "B"])
    for i in 1:5
        addpoint!(
            plot,
            Dict("A" => Float64(i), "B" => Float64(i)^2);
            show = false,
        )
    end
    @test plot.history["A"] == [3.0, 4.0, 5.0]
    @test plot.history["B"] == [9.0, 16.0, 25.0]
    closeplot!(plot)
    PyPlot.close(plot.backend.fig)

    # addpoint! returns the plot.
    plot = ConvergencePlot()
    @test addpoint!(plot, 1.0; show = false) === plot
    closeplot!(plot)
    PyPlot.close(plot.backend.fig)

    # Invalid inputs.
    plot = ConvergencePlot(3, names = ["A", "B"])
    @test_throws AssertionError addpoint!(plot, 1.0; show = false)
    @test_throws AssertionError addpoint!(plot, Dict("C" => 1.0); show = false)
    closeplot!(plot)
    PyPlot.close(plot.backend.fig)
end

@testset "addpoints!" begin
    # Appending when there is still room in the history window.
    plot = ConvergencePlot(5)
    addpoint!(plot, 1.0; show = false)
    addpoints!(plot, Dict("Residual" => [2.0, 3.0]); show = false)
    @test plot.history["Residual"] == [1.0, 2.0, 3.0]
    closeplot!(plot)
    PyPlot.close(plot.backend.fig)

    # Windowing when the batch does not fit.
    plot = ConvergencePlot(5)
    for i in 1:5
        addpoint!(plot, Float64(i); show = false)
    end
    addpoints!(plot, Dict("Residual" => [6.0, 7.0, 8.0]); show = false)
    @test plot.history["Residual"] == [4.0, 5.0, 6.0, 7.0, 8.0]
    closeplot!(plot)
    PyPlot.close(plot.backend.fig)

    # A batch longer than npoints keeps only its last npoints points.
    plot = ConvergencePlot(3)
    addpoints!(plot, Dict("Residual" => [1.0, 2.0, 3.0, 4.0, 5.0]))
    @test plot.history["Residual"] == [3.0, 4.0, 5.0]
    closeplot!(plot)
    PyPlot.close(plot.backend.fig)

    # A batch of exactly npoints points replaces the history.
    plot = ConvergencePlot(3)
    addpoint!(plot, 1.0; show = false)
    addpoints!(plot, Dict("Residual" => [4.0, 5.0, 6.0]))
    @test plot.history["Residual"] == [4.0, 5.0, 6.0]
    closeplot!(plot)
    PyPlot.close(plot.backend.fig)

    # addpoints! returns the plot and rejects unknown names.
    plot = ConvergencePlot(3)
    @test addpoints!(plot, Dict("Residual" => [1.0, 2.0])) === plot
    @test_throws AssertionError addpoints!(plot, Dict("C" => [1.0]))
    closeplot!(plot)
    PyPlot.close(plot.backend.fig)
end

@testset "options" begin
    # Default options.
    options = ConvergencePlots.getoptions(["A", "B"], nothing)
    @test options["A"].label == "A"
    @test options["B"].label == "B"
    @test all(haskey(o, :color) for o in values(options))
    @test options["A"].color != options["B"].color

    # A dictionary of options with explicit labels.
    options = ConvergencePlots.getoptions(
        ["A", "B"],
        Dict("A" => (label = "X", ls = "--"), "B" => (label = "Y",)),
    )
    @test options["A"].label == "X"
    @test options["A"].ls == "--"
    @test options["B"].label == "Y"

    # A dictionary of options without labels defaults to the names.
    options = ConvergencePlots.getoptions(
        ["A", "B"],
        Dict("A" => (ls = "--",), "B" => (ls = ":",)),
    )
    @test options["A"].label == "A"
    @test options["A"].ls == "--"
    @test options["B"].label == "B"
    @test options["B"].ls == ":"

    # Missing names in the dictionary fall back to the default options.
    options = ConvergencePlots.getoptions(["A", "B"], Dict("A" => (ls = "--",)))
    @test options["A"].ls == "--"
    @test options["B"].label == "B"

    # A single NamedTuple of options is used for all the names.
    options = ConvergencePlots.getoptions(["A", "B"], (ls = "--",))
    @test options["A"].label == "A"
    @test options["A"].ls == "--"
    @test options["B"].label == "B"
    @test options["B"].ls == "--"

    # User-provided colors are preserved.
    options = ConvergencePlots.getoptions(
        ["A", "B"],
        Dict("A" => (color = :red,), "B" => (color = "blue",)),
    )
    @test options["A"].color == :red
    @test options["B"].color == "blue"

    # The default colors are deterministic and distinct.
    options1 = ConvergencePlots.getoptions(["A", "B", "C"], nothing)
    options2 = ConvergencePlots.getoptions(["A", "B", "C"], nothing)
    for n in ["A", "B", "C"]
        @test options1[n].color == options2[n].color
    end
    colors = [ConvergencePlots.defaultcolor(i) for i in 1:50]
    @test length(unique(colors)) == 50
end

@testset "defaultcolor" begin
    c = ConvergencePlots.defaultcolor(1)
    @test c isa RGB{Float64}
    @test all(0 .<= (c.r, c.g, c.b) .<= 1)
    @test c == ConvergencePlots.defaultcolor(1)
    @test c != ConvergencePlots.defaultcolor(2)
end

@testset "emptyplot" begin
    for (ncurves, nsubplots) in [(1, 1), (2, 1), (3, 2), (4, 2), (5, 3)]
        fig, axs = PyPlotExt.emptyplot(ncurves, (4, 3))
        @test length(axs) == ncurves
        # Every pair of curves shares an x-axis through twinx.
        for i in 1:2:ncurves
            if i < ncurves
                @test axs[i + 1] !== axs[i]
                @test axs[i + 1].get_shared_x_axes().joined(axs[i], axs[i + 1])
            end
        end
        PyPlot.close(fig)
    end
end

@testset "keepinteractive" begin
    PyPlot.ion()
    PyPlotExt.keepinteractive() do
        @test !PyPlot.isinteractive()
    end
    @test PyPlot.isinteractive()
    PyPlot.ioff()
    PyPlotExt.keepinteractive() do
        @test !PyPlot.isinteractive()
    end
    @test !PyPlot.isinteractive()
end

@testset "updateplot!" begin
    plot = ConvergencePlot(names = ["A", "B"])
    addpoint!(plot, Dict("A" => 1.0, "B" => 2.0); show = false)
    @test length(plot.backend.axs[1].get_lines()) == 1
    @test length(plot.backend.axs[2].get_lines()) == 1
    @test updateplot!(plot; show = false) === plot

    # Saving the figure to a file.
    mktempdir() do dir
        filename = joinpath(dir, "fig.png")
        updateplot!(plot; show = false, filename = filename)
        @test isfile(filename)
    end
    closeplot!(plot)
    PyPlot.close(plot.backend.fig)
end

@testset "closeplot!" begin
    plot = ConvergencePlot()
    oldfig = plot.backend.fig
    closeplot!(plot)
    @test plot.backend.fig !== oldfig
    @test length(plot.backend.axs) == 1
    # The new plot is empty and usable.
    addpoint!(plot, 1.0; show = false)
    @test plot.history["Residual"] == [1.0]
    PyPlot.close(plot.backend.fig)
end
