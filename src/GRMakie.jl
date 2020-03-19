module GRMakie

using AbstractPlotting
using Colors, Printf
import GR

import AbstractPlotting: backend_showable, backend_show

include("utils.jl")
include("primitives.jl")
include("saving.jl")

struct GRBackend <: AbstractPlotting.AbstractBackend
end

function AbstractPlotting.backend_display(::GRBackend, scene::Scene)
    AbstractPlotting.update!(scene)
    ENV["GKS_DOUBLE_BUF"] = true
    GR.clearws()
    draw(scene)
    GR.updatews()
end

struct GRScreen <: AbstractPlotting.AbstractScreen
    scene::Scene
end

# TODO we need to revamp these!
Base.insert!(screen::GRScreen, scene::Scene, plot) = nothing

AbstractPlotting.push_screen!(scene::Scene, ::Nothing) = nothing

# Provides an in-memory buffer for the plot as an image.
# Used in the AbstractPlotting standard record function,
# but in the case of GR, that can be replaced by the GR
# native recording functions.
function AbstractPlotting.colorbuffer(scr::GRScreen)
    scene = scr.scene
    height, width = widths(pixelarea(scene)[])
    rcmat = Array{UInt8}(undef, 4, width, height)   # GR outputs row major images to memory.
    ncmat = Array{RGBA}(undef, width, height)       # We need to return a matrix of colors.
    pstr = @sprintf "%p" Int(pointer(rcmat)) # Print in octal notation
    GR.beginprint("!$(width)x$(height)@$(pstr).mem")
    draw(scene)
    GR.endprint()
    for i in 1:height, j in 1:width
        ncmat[j, i] = AbstractPlotting.Colors.RGBA((rcmat[:, j, i] ./ 255)...) # divide by 255 to move to N0f8
    end

    return ncmat
end

function activate!()
    AbstractPlotting.current_backend[] = GRBackend()
end

function __init__()
    activate!()
    ENV["GKS_ENCODING"] = haskey(ENV, "GKS_ENCODING") ? ENV["GKS_ENCODING"] : "utf-8"
    GR.selntran(0)
end


end # module
