
"""
    `lines(x, y, z)` / `lines(x, y)` / `lines(positions)`

Creates a connected line plot for each element in `(x, y, z)`, `(x, y)` or `positions`.
"""
function draw(scene::Scene, plot::Lines)
    positions = map(plot[1][]) do pos
        # take camera from scene + model transformation matrix and apply it to pos
        project_position(scene, pos, plot[:model][])
    end
    @show positions
    GR.polyline(first.(positions), last.(positions))
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
    #@show positions
    #@show color
    #@show linewidth
    #@show linestyle
    colors = if color[] isa Colors.Colorant
            [color for i in 1:length(positions)]
        else
            color
        end

    broadcast_foreach(1:length(positions), color[], linewidth[], linestyle[]) do i, c, lw, ls
        if !iseven(i)
            GR.setlinewidth(lw)
            GR.setlinecolorind(Int(GR.inqcolorfromrgb(red(c), green(c), blue(c))))
            GR.settransparency(alpha(c))
            a, b = positions[i], positions[i + 1]
            GR.polyline([a[1], b[1]], [a[2], b[2]])
        end
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
        GR.settextfontprec(27, 0)
        GR.setcharheight(0.022) # ts ?
        GR.settextcolorind(Int(GR.inqcolorfromrgb(cc.r, cc.g, cc.b)))
        GR.settransparency(cc.alpha)
        @show pos txt[i]
        GR.text(pos[1], pos[2], string(txt[i]))
    end
end

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

# The toplevel method - this draws all plots and child scenes
function draw(scene::Scene)
    foreach(plot-> draw(scene, plot), scene.plots)
    foreach(child-> draw(child), scene.children)
end

# The lower level method.  This dispatches on primitives, meaning that
# we have some guarantees about their attributes.
function draw(scene::Scene, primitive::AbstractPlotting.Combined)
    foreach(x-> draw(scene, x), filter(x -> x.visible[], primitive.plots))
end
