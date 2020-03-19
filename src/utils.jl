function project_position(scene, point, model)
    p4d = to_ndim(Vec4f0, to_ndim(Vec3f0, point, 0f0), 1f0)
    clip = scene.camera.projectionview[] * model * p4d
    p = (clip / clip[4])[Vec(1, 2)]
    (p .+ 1) ./ 2
end

project_scale(scene::Scene, s::Number) = project_scale(scene, Vec2f0(s))

function project_scale(scene::Scene, s)
    p4d = to_ndim(Vec4f0, s, 0f0)
    p = (scene.camera.projectionview[] * p4d)[Vec(1, 2)] ./ 2f0
end

const marker_translation_table = Dict(
    '■' => GR.MARKERTYPE_SOLID_SQUARE,
    '★' => GR.MARKERTYPE_SOLID_STAR,
    '◆' => GR.MARKERTYPE_SOLID_DIAMOND,
    '⬢' => GR.MARKERTYPE_HEXAGON,
    '✚' => GR.MARKERTYPE_SOLID_PLUS,
    '❌' => GR.MARKERTYPE_DIAGONAL_CROSS,
    '▲' => GR.MARKERTYPE_SOLID_TRI_UP,
    '▼' => GR.MARKERTYPE_SOLID_TRI_DOWN,
    '◀' => GR.MARKERTYPE_SOLID_TRI_LEFT,
    '▶' => GR.MARKERTYPE_SOLID_TRI_RIGHT,
    '⬟' => GR.MARKERTYPE_PENTAGON,
    '⯄' => GR.MARKERTYPE_OCTAGON,
    '✦' => GR.MARKERTYPE_STAR_4,
    '🟋' => GR.MARKERTYPE_STAR_6,
    '✷' => GR.MARKERTYPE_STAR_8,
    '┃' => GR.MARKERTYPE_VLINE,
    '━' => GR.MARKERTYPE_HLINE,
    '+' => GR.MARKERTYPE_PLUS,
    'x' => GR.MARKERTYPE_DIAGONAL_CROSS,
    '●' => GR.MARKERTYPE_SOLID_CIRCLE
)

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
