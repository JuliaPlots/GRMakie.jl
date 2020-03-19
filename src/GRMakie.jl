module GRMakie

using AbstractPlotting
using Printf
import GR

function project_position(scene, point, model)
    p4d = to_ndim(Vec4f0, to_ndim(Vec3f0, point, 0f0), 1f0)
    clip = scene.camera.projectionview[] * model * p4d
    p = (clip / clip[4])[Vec(1, 2)]
    # (p .+ 1) ./ 2
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

"""
    `scatter(x, y, z)` / `scatter(x, y)` / `scatter(positions)`

Plots a marker for each element in `(x, y, z)`, `(x, y)`, or `positions`.
"""
function draw(scene::Scene, plot::Scatter)
    fields = @get_attribute(plot, (color, markersize, strokecolor, strokewidth, marker))
    model = plot[:model][]
    broadcast_foreach(plot[1][], fields...) do point, c, markersize, strokecolor, strokewidth, marker
        scale = project_scale(scene, markersize)[1] * 2500 / 6
        pos = project_position(scene, point, model)
        GR.setmarkertype(get(marker_translation_table, marker, GR.MARKERTYPE_SOLID_CIRCLE))
        GR.setmarkersize(scale)
        GR.setmarkercolorind(Int(GR.inqcolorfromrgb(c.r, c.g, c.b)))
        GR.settransparency(c.alpha)
        GR.polymarker([pos[1]], [pos[2]])
    end
end

"""
    `image(x, y, image)` / `image(image)`

Plots an image on range `x, y` (defaults to dimensions).
"""
function draw(scene::Scene, plot::Image)
    @get_attribute plot (colormap, colorrange)
end


# could be implemented via image, but might be optimized specifically by the backend
"""
    `heatmap(x, y, values)` or `heatmap(values)`

Plots a heatmap as an image on `x, y` (defaults to interpretation as dimensions).
"""
function draw(scene::Scene, plot::Heatmap)
    @get_attribute(plot, (colormap,colorrange,linewidth,levels,fxaa,interpolate))
end

"""
    `volume(volume_data)`

Plots a volume. Available algorithms are:
* `:iso` => IsoValue
* `:absorption` => Absorption
* `:mip` => MaximumIntensityProjection
* `:absorptionrgba` => AbsorptionRGBA
* `:indexedabsorption` => IndexedAbsorptionRGBA
"""
function draw(scene::Scene, plot::Volume)
    @get_attribute(plot, (algorithm,absorption,isovalue,isorange,colormap,colorrange))

end

"""
    `surface(x, y, z)`

Plots a surface, where `(x, y, z)` are supposed to lie on a grid.
"""
function draw(scene::Scene, plot::Surface)
    @get_attribute(plot, (colormap,colorrange,shading))
end

"""
    `lines(x, y, z)` / `lines(x, y)` / or `lines(positions)`

Creates a connected line plot for each element in `(x, y, z)`, `(x, y)` or `positions`.
"""
function draw(scene::Scene, plot::Lines)
    positions = map(plot[1][]) do pos
        # take camera from scene + model transformation matrix and apply it to pos
        project_position(scene, pos, plot[:model][])
    end
    GR.polyline(first.(positions), last.(positions))
end

"""
    `linesegments(x, y, z)` / `linesegments(x, y)` / `linesegments(positions)`

Plots a line for each pair of points in `(x, y, z)`, `(x, y)`, or `positions`.

**Attributes**:
The same as for [`lines`](@ref)
"""
function draw(scene::Scene, plot::LineSegments)
    positions = map(plot[1][]) do pos
        # take camera from scene + model transformation matrix and apply it to pos
        project_position(scene, pos, plot[:model][])
    end
    @get_attribute(plot, (color, linewidth, linestyle))
    #@show positions
    #@show color
    #@show linewidth
    #@show linestyle
    for i in 1:2:length(positions)
        GR.setlinewidth(linewidth[i])
        GR.setlinecolorind(Int(GR.inqcolorfromrgb(color[i].r, color[i].g, color[i].b)))
        GR.settransparency(color[i].alpha)
        a, b = positions[i], positions[i + 1]
        GR.polyline([a[1], b[1]], [a[2], b[2]])
    end
end

function draw(scene::Scene, primitive::AbstractPlotting.Combined)
    foreach(x-> draw(scene, x), primitive.plots)
end

# alternatively, mesh3d? Or having only mesh instead of poly + mesh and figure out 2d/3d via dispatch
"""
    `mesh(x, y, z)`, `mesh(mesh_object)`, `mesh(x, y, z, faces)`, or `mesh(xyz, faces)`

Plots a 3D mesh.
"""
function draw(scene::Scene, plot::Mesh)
    @get_attribute(plot, (interpolate,shading,colormap,colorrange))
end


"""
    `meshscatter(x, y, z)` / `meshscatter(x, y)` / `meshscatter(positions)`

Plots a mesh for each element in `(x, y, z)`, `(x, y)`, or `positions` (similar to `scatter`).
`markersize` is a scaling applied to the primitive passed as `marker`
"""
function draw(scene::Scene, plot::MeshScatter)
    @get_attribute(plot, (marker,markersize,rotations,colormap,colorrange))
end

"""
    `text(string)`

Plots a text.
"""
function draw(scene::Scene, plot::AbstractPlotting.Text)
    @get_attribute(plot, (textsize, color, font, align, rotation, model))
    txt = to_value(plot[1])
    position = plot.attributes[:position][]
    N = length(txt)
    broadcast_foreach(1:N, position, textsize, color, font, rotation) do i, p, ts, cc, f, r
        pos = project_position(scene, p, model)
        chup = r * Vec2f0(0, 1)
        GR.setcharup(chup[1], chup[2])
        GR.settextfontprec(27, 0)
        GR.setcharheight(norm(ts)*0.11) # ts ?
        GR.settextcolorind(Int(GR.inqcolorfromrgb(cc.r, cc.g, cc.b)))
        GR.settransparency(cc.alpha)
        GR.text(pos[1], pos[2], string(txt[i]))
    end
end

function draw(scene::Scene)
    foreach(plot-> draw(scene, plot), filter(x -> x.visible[], scene.plots))
    foreach(child-> draw(child), scene.children)
end

struct GRBackend <: AbstractPlotting.AbstractBackend
end

function AbstractPlotting.backend_display(::GRBackend, scene::Scene)
    AbstractPlotting.update!(scene)
    ENV["GKS_DOUBLE_BUF"] = true
    GR.clearws()
    draw(scene)
    GR.updatews()
end

const GR_SUPPORTED_TYPES = Union{
    MIME"image/svg", MIME"image/svg+xml", MIME"image/png", MIME"image/jpeg",
    MIME"image/tiff", MIME"image/bmp", MIME"application/pdf",
    MIME"application/postscript", MIME"application/x-tex"
}

AbstractPlotting.backend_showable(::GRBackend, ::GR_SUPPORTED_TYPES, scene::SceneLike) = true

AbstractPlotting.format2mime(::Type{AbstractPlotting.FileIO.DataFormat{:TIFF}}) = MIME("image/tiff")
AbstractPlotting.format2mime(::Type{AbstractPlotting.FileIO.DataFormat{:BMP}}) = MIME("image/bmp")
AbstractPlotting.format2mime(::Type{AbstractPlotting.FileIO.DataFormat{:PDF}}) = MIME("application/pdf")
AbstractPlotting.format2mime(::Type{AbstractPlotting.FileIO.DataFormat{:TEX}}) = MIME("application/x-tex")
AbstractPlotting.format2mime(::Type{AbstractPlotting.FileIO.DataFormat{:EPS}}) = MIME("application/postscript")

function gr_save(io, scene, filetype)
    fp = tempname() * "." * filetype

    touch(fp)

    GR.beginprint(fp)
    draw(scene)
    GR.endprint()

    write(io, read(fp))

    rm(fp)
end

function AbstractPlotting.backend_show(::GRBackend, io::IO, ::MIME"image/png", scene::Scene)
    AbstractPlotting.update!(scene)
    GR.emergencyclosegks()
    gr_save(io, scene, "png")
end

function AbstractPlotting.backend_show(::GRBackend, io::IO, ::MIME"image/jpeg", scene::Scene)
    AbstractPlotting.update!(scene)
    GR.emergencyclosegks()
    gr_save(io, scene, "jpeg")
end

function AbstractPlotting.backend_show(::GRBackend, io::IO, ::MIME"image/bmp", scene::Scene)
    AbstractPlotting.update!(scene)
    GR.emergencyclosegks()
    gr_save(io, scene, "bmp")
end

function AbstractPlotting.backend_show(::GRBackend, io::IO, ::MIME"image/tiff", scene::Scene)
    AbstractPlotting.update!(scene)
    GR.emergencyclosegks()
    gr_save(io, scene, "tiff")
end

function AbstractPlotting.backend_show(::GRBackend, io::IO, ::Union{MIME"image/svg", MIME"image/svg+xml"}, scene::Scene)
    AbstractPlotting.update!(scene)
    GR.emergencyclosegks()
    gr_save(io, scene, "svg")
end

function AbstractPlotting.backend_show(::GRBackend, io::IO, ::MIME"application/pdf", scene::Scene)
    AbstractPlotting.update!(scene)
    GR.emergencyclosegks()
    gr_save(io, scene, "pdf")
end

function AbstractPlotting.backend_show(::GRBackend, io::IO, ::MIME"application/postscript", scene::Scene)
    AbstractPlotting.update!(scene)
    GR.emergencyclosegks()
    gr_save(io, scene, "eps")
end

function AbstractPlotting.backend_show(::GRBackend, io::IO, ::MIME"application/x-tex", scene::Scene)
    AbstractPlotting.update!(scene)
    GR.emergencyclosegks()
    fp = tempname() * ".tex"
    withenv("GKS_WSTYPE" => "pgf", "GKS_FILEPATH" => fp) do
        GR.clearws()
        draw(scene)
        GR.updatews()
        GR.emergencyclosegks()
    end

    write(io, read(fp))
end

function AbstractPlotting.colorbuffer(scr::GRScreen)
    scene = scr.scene
    width, height = pixelarea(scene)[]
    rcmat = Array{UInt8}(4, width, height)   # GR outputs row major images to memory.
    ncmat = Array{AbstractPlotting.Colors.RGBA}(width, height)   # We need to return a matrix of colors.
    pstr = @sprintf "%p" Int(pointer(rcmat)) # Print in octal notation
    GR.beginprint("!$(width)x$(height)@$(pstr).mem")
    draw(scene)
    GR.endprint()
    for i in 1:height, j in 1:width
        ncmat[j, i] = AbstractPlotting.Colors.RGBA((rcmat[:, i, j] ./ 255)...) # divide by 255 to move to N0f8
    end

    return ncmat
end

struct GRScreen <: AbstractPlotting.AbstractScreen
    scene::Scene
end

Base.insert!(screen::GRScreen, scene::Scene, plot) = nothing

AbstractPlotting.push_screen!(scene::Scene, ::Nothing) = nothing

function __init__()
    activate!()
    ENV["GKS_ENCODING"] = haskey(ENV, "GKS_ENCODING") ? ENV["GKS_ENCODING"] : "utf-8"
end

function activate!()
    AbstractPlotting.current_backend[] = GRBackend()
end


end # module
