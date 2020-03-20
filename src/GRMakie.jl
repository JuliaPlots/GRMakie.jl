module GRMakie

using AbstractPlotting
using Colors, Printf
import GR

import AbstractPlotting: backend_showable, backend_show

using AbstractPlotting.IntervalSets: ClosedInterval

include("utils.jl")
include("primitives.jl")
include("saving.jl")

function activate!()
    AbstractPlotting.current_backend[] = GRBackend()
end

function __init__()
    activate!()
    ENV["GKS_ENCODING"] = haskey(ENV, "GKS_ENCODING") ? ENV["GKS_ENCODING"] : "utf-8"
    GR.selntran(0)
end


end # module
