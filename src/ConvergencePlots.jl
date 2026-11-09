module ConvergencePlots

export AbstractPlotBackend,
    default_backend,
    pyplotbackend,
    plotsbackend,
    makiebackend,
    ConvergencePlot,
    addpoint!,
    addpoints!,
    updateplot!,
    closeplot!

using Parameters
using Colors: RGB, HSV

include("backend.jl")
include("options.jl")
include("plot.jl")

end
