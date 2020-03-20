
gr_poly_line(points::Vector{Vec2f0}) = GR.polyline(first.(points), last.(points))
gr_poly_line(points::Vector{Vec3f0}) = GR.polyline(first.(points), getindex.(points, 2), last.(points))

"""
    `lines(x, y, z)` / `lines(x, y)` / `lines(positions)`

Creates a connected line plot for each element in `(x, y, z)`, `(x, y)` or `positions`.
"""
function draw(scene::Scene, plot::Lines)
    # TODO:
    # - Continuous color (`color = 1:10`)
    positions = map(plot[1][]) do pos
        # take camera from scene + model transformation matrix and apply it to pos
        project_position(scene, pos, plot[:model][])
    end

    c = if plot.color[] isa Symbol
            parse(Colorant, plot.color[])
        elseif plot.color[] isa Tuple{Symbol, Float64}
            RGBA(parse(Colorant, plot.color[][1]), plot.color[][2])
        else
            plot.color[]
        end
    # TODO change this to an array

    GR.settransparency(alpha(c))
    GR.setlinecolorind(gr_colorind(c))
    GR.setlinewidth(plot.linewidth[])
    gr_poly_line(positions)
    # broadcast_foreach(1:length(positions), plot.color[], plot.linewidth[], plot.linestyle[]) do i, c, lw, ls
        # GR.settransparency(alpha(c))
        # GR.setlinecolorind(gr_color(c))
    #     GR.polyline(x, y, )
    # end
end

"""
    linesegments(positions)

Plots a line for each pair of points in `positions`.

**Attributes**:
The same as for [`lines`](@ref)
"""
function draw(scene::Scene, plot::LineSegments)
    positions = map(plot[1][]) do pos
        # take camera from scene + model transformation matrix and apply it to pos
        project_position(scene, pos, plot[:model][])
    end
    @get_attribute(plot, (color, linewidth, linestyle))
    if color isa Union{RGBA, Symbol}
        color = fill(RGBA(color), length(positions))
    end
    if linewidth isa Number
        linewidth = fill(linewidth, length(positions))
    end
    #@show positions
    #@show color
    #@show linewidth
    #@show linestyle
    for i in 1:2:length(positions)
        GR.settransparency(alpha(color[i]))
        GR.setlinecolorind(gr_colorind(color[i]))
        GR.setlinewidth(linewidth[i])
        gr_poly_line(positions[i:(i+1)])
    end
end

"""
    text(string)

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
        GR.settextfontprec(233, 3)
        GR.setcharheight(0.018) # ts ???
        GR.settextcolorind(Int(GR.inqcolorfromrgb(cc.r, cc.g, cc.b)))
        GR.settransparency(cc.alpha)
        GR.settextalign(1, 4)
        GR.text(pos[1], pos[2], string(txt[i]))
    end
end

"""
    `scatter(x, y, z)` / `scatter(x, y)` / `scatter(positions)`

Plots a marker for each element in `(x, y, z)`, `(x, y)`, or `positions`.
"""
function draw(scene::Scene, plot::Scatter)
    fields = @get_attribute(plot, (color, colormap, colorrange, markersize, strokecolor, strokewidth, marker))
    model = plot[:model][]
    color isa AbstractVector && (color = to_image(collect(color), plot))
    broadcast_foreach(plot[1][], color, markersize, strokecolor, strokewidth, marker) do point, c, markersize, strokecolor, strokewidth, marker
        scale = project_scale(scene, markersize)[1] * 2500 / 6
        pos = project_position(scene, point, model)
        GR.setmarkertype(get(marker_translation_table, marker, GR.MARKERTYPE_SOLID_CIRCLE))
        GR.setmarkersize(scale)
        GR.setbordercolorind(gr_colorind(strokecolor))
        GR.setborderwidth(strokewidth)
        GR.setmarkercolorind(gr_colorind(c))
        GR.settransparency(alpha(c))
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

to_image(values::VecOrMat{<: Colorant}, attributes) = RGBA.(values)
function to_image(values::VecOrMat{<: Real}, attributes)
    AbstractPlotting.@get_attribute attributes (colormap, colorrange)
    return AbstractPlotting.interpolated_getindex.(Ref(colormap), values, (colorrange,))
end
# could be implemented via image, but might be optimized specifically by the backend
"""
    `heatmap(x, y, values)` or `heatmap(values)`

Plots a heatmap as an image on `x, y` (defaults to interpretation as dimensions).
"""
function draw(scene::Scene, plot::Heatmap)
    # TODO:
    # - get interpolation working consistently
    # - get levels to work, if they even do
    @get_attribute(plot, (colormap,colorrange,linewidth,levels,fxaa,interpolate))

    image = plot[3][]
    x, y = plot[1][], plot[2][]
    model = plot.model[]

    interp = plot.interpolate[]

    imsize = (AbstractPlotting.extrema_nan(x), AbstractPlotting.extrema_nan(y))

    _xy_min = project_position(scene, Point2f0(first.(imsize)), model)
    _xy_max = project_position(scene, Point2f0(last.(imsize)), model)

    if is_uniformly_spaced(x) && is_uniformly_spaced(y)

        xy_min = min.(_xy_min, _xy_max)
        xy_max = max.(_xy_min, _xy_max)

        colors = gr_color.(to_image(image, plot))

        # Main.@infiltrate

        GR.drawimage(
            xy_min[1],
            xy_max[1],
            xy_min[2],
            xy_max[2],
            size(image)[1],
            size(image)[2],
            colors
        )
    end
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

    x, y, z = plot[1][], plot[2][], plot[3][]
    if algorithm == AbstractPlotting.MaximumIntensityProjection

    end
end

"""
    `surface(x, y, z)`

Plots a surface, where `(x, y, z)` are supposed to lie on a grid.
"""
function draw(scene::Scene, plot::Surface)
    # TODO:
    # - transform x and y points into the screen's space
    @get_attribute(plot, (colormap,colorrange,shading))
    cmap = AbstractPlotting.to_colormap(colormap)

    x, y, z = plot[1][], plot[2][], plot[3][]

    GR.setcolormapfromrgb(red.(cmap), green.(cmap), blue.(cmap))

    if is_uniformly_spaced(x) && is_uniformly_spaced(y)
        x = ensure_vector(x; size = size(z)[1])
        y = ensure_vector(y; size = size(z)[2])
        # points = Point2f0.(x, y)
        # positions = map(points) do pos
        #     # take camera from scene + model transformation matrix and apply it to pos
        #     project_position(scene, pos, plot[:model][])
        # end
        # x, y = first.(positions), last.(positions)
        GR.surface(x, y, z, 4) # 4 => COLORED_MESH
    end
end

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

function setup_plot(scene)
    mwidth, mheight, width, height = GR.inqdspsize()
    size_factor = 0.25  # 25% of the display width
    w, h = scene.camera.resolution[]
    if w > h
        GR.setwsviewport(0, size_factor * mwidth, 0, size_factor * mwidth * h / w)
        GR.setwswindow(0, 1, 0, h / w)
    else
        GR.setwsviewport(0, size_factor * mheight * w / h, 0, size_factor * mheight)
        GR.setwswindow(0, w / h, 0, 1)
    end
    GR.selntran(0)
end

# The toplevel method - this sets up GR attributes, et cetera
function gr_draw(scene::Scene)
    setup_plot(scene)
    draw(scene)
end
# The main method - this draws all plots and child scenes
function draw(scene::Scene)
    foreach(plot-> draw(scene, plot), scene.plots)
    foreach(child-> draw(child), scene.children)
end
# The lower level method.  This dispatches on primitives, meaning that
# we have some guarantees about their attributes.
function draw(scene::Scene, primitive::AbstractPlotting.Combined)
    foreach(x-> draw(scene, x), filter(x -> x.visible[], primitive.plots))
end
