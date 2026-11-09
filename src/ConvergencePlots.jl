module ConvergencePlots

export ConvergencePlot,
    addpoint!,
    addpoints!,
    updateplot!,
    closeplot!

using PyPlot, Parameters, Random

include("options.jl")
include("plot.jl")

end
