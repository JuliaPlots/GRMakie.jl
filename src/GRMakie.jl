module GRMakie

using AbstractPlotting
using Colors, Printf
import GR

import AbstractPlotting: backend_showable, backend_show

include("utils.jl")
include("primitives.jl")
include("saving.jl")


Base.show(io::IO, ::MIME"text/plain", scene::Scene) = (
    withenv("GKS_WSTYPE" => "0") do
        AbstractPlotting.update!(scene)
        GR.clearws()
        draw(scene)
        GR.updatews()
    end
)

function activate!()
    AbstractPlotting.current_backend[] = GRBackend()
end

function __init__()
    activate!()
    ENV["GKS_ENCODING"] = haskey(ENV, "GKS_ENCODING") ? ENV["GKS_ENCODING"] : "utf-8"
    GR.selntran(0)
end


end # module
