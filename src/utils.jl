function project_position(scene, point, model)
    p4d = to_ndim(Vec4f0, to_ndim(Vec3f0, point, 0f0), 1f0)
    clip = scene.camera.projectionview[] * model * p4d
    p = (clip / clip[4])[Vec(1, 2)]
    p = collect((p .+ 1) ./ 2)
    w, h = scene.camera.resolution[]
    if w > h
        p[2:2:end] .*= (h / w)
    else
        p[1:2:end] .*= (w / h)
    end
    return Vec2f0(p)
end

project_scale(scene::Scene, s::Number) = project_scale(scene, Vec2f0(s))

function project_scale(scene::Scene, s)
    p4d = to_ndim(Vec4f0, s, 0f0)
    p = (scene.camera.projectionview[] * p4d)[Vec(1, 2)] ./ 2f0
    return Vec2f0(p)
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

# Color utilities
gr_color(c) = gr_color(c, color_type(c))
gr_color(c, ::Type) = gr_color(RGBA(c), RGB) # generic fallback
gr_color(c, ::Symbol) = gr_color(Colors.colorant(c), RGB)
function gr_color(c, ::Type{<:AbstractRGB})
    return UInt32(
        round(UInt, clamp(alpha(c) * 255, 0, 255)) << 24 +
        round(UInt,  clamp(blue(c) * 255, 0, 255)) << 16 +
        round(UInt, clamp(green(c) * 255, 0, 255)) << 8  +
        round(UInt,   clamp(red(c) * 255, 0, 255))
    )
end
function gr_color(c, ::Type{<:AbstractGray})
    g = round(UInt, clamp(gray(c) * 255, 0, 255))
    α = round(UInt, clamp(alpha(c) * 255, 0, 255))
    return UInt32( α<<24 + g<<16 + g<<8 + g )
end

function gr_colorind(c)
    convert(Int, GR.inqcolorfromrgb(red(c), green(c), blue(c)))
end

# Heatmap positioning
function is_uniformly_spaced(v; tol=1e-6)
  dv = diff(v)
  maximum(dv) - minimum(dv) < tol * mean(abs.(dv))
end

is_uniformly_spaced(::AbstractPlotting.ClosedInterval) = true

is_uniformly_spaced(::AbstractRange) = true

# surface utilities
# This function will return a vector form of `x` and `y`
# if needed, taking the lengths from `z`.
function ensure_vector(x::AbstractRange; size)
    return collect(x)
end
function ensure_vector(x::Vector; size)
    return x
end
function ensure_vector(x::ClosedInterval; size)
    return collect(LinRange(extrema(x)..., size))
end
# Backend utilities
struct GRBackend <: AbstractPlotting.AbstractBackend
end
struct GRScreen <: AbstractPlotting.AbstractScreen
    scene::Scene
end

function AbstractPlotting.backend_display(::GRBackend, scene::Scene)
    withenv("GKS_WSTYPE" => "0") do
        AbstractPlotting.update!(scene)
        GR.clearws()
        gr_draw(scene)
        GR.updatews()
    end
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
    rcmat = Array{UInt8}(undef, 4, width, height) # GR outputs row major images to memory.
    ncmat = Array{RGBA}(undef, width, height)     # We need to return a matrix of colors.
    pstr = @sprintf "%p" Int(pointer(rcmat))      # Print in octal notation
    GR.beginprint("!$(width)x$(height)@$(pstr).mem")
    draw(scene)
    GR.endprint()
    for i in 1:height, j in 1:width
        ncmat[j, i] = AbstractPlotting.Colors.RGBA((rcmat[:, j, i] ./ 255)...) # divide by 255 to move to N0f8
    end

    return ncmat
end
