
const GR_SUPPORTED_TYPES = Union{
    MIME"image/svg", MIME"image/svg+xml", MIME"image/png", MIME"image/jpeg",
    MIME"image/tiff", MIME"image/bmp", MIME"application/pdf",
    MIME"application/postscript", MIME"application/x-tex", MIME"text/plain"
}

backend_showable(::GRBackend, ::GR_SUPPORTED_TYPES, scene::SceneLike) = true

function gr_save(io, scene, filetype)
    fp = tempname() * "." * filetype

    touch(fp)

    GR.beginprint(fp)
    draw(scene)
    GR.endprint()

    write(io, read(fp))

    rm(fp)
end

function backend_show(::GRBackend, io::IO, ::MIME"image/png", scene::Scene)
    AbstractPlotting.update!(scene)
    gr_save(io, scene, "png")
end

function backend_show(::GRBackend, io::IO, ::MIME"image/jpeg", scene::Scene)
    AbstractPlotting.update!(scene)
    gr_save(io, scene, "jpeg")
end

function backend_show(::GRBackend, io::IO, ::MIME"image/bmp", scene::Scene)
    AbstractPlotting.update!(scene)
    gr_save(io, scene, "bmp")
end

function backend_show(::GRBackend, io::IO, ::MIME"image/tiff", scene::Scene)
    AbstractPlotting.update!(scene)
    gr_save(io, scene, "tiff")
end

function backend_show(::GRBackend, io::IO, ::Union{MIME"image/svg", MIME"image/svg+xml"}, scene::Scene)
    AbstractPlotting.update!(scene)
    gr_save(io, scene, "svg")
end

function backend_show(::GRBackend, io::IO, ::MIME"application/pdf", scene::Scene)
    AbstractPlotting.update!(scene)
    gr_save(io, scene, "pdf")
end

function backend_show(::GRBackend, io::IO, ::MIME"application/postscript", scene::Scene)
    AbstractPlotting.update!(scene)
    gr_save(io, scene, "eps")
end

function backend_show(::GRBackend, io::IO, ::MIME"application/x-tex", scene::Scene)
    AbstractPlotting.update!(scene)
    fp = tempname() * ".tex"
    withenv("GKS_WSTYPE" => "pgf", "GKS_FILEPATH" => fp) do
        GR.clearws()
        draw(scene)
        GR.updatews()
    end

    write(io, read(fp))
end

function backend_show(::GRBackend, io::IO, ::MIME"text/plain", scene::Scene)
    withenv("GKS_WSTYPE" => "0") do
        AbstractPlotting.update!(scene)
        GR.clearws()
        draw(scene)
        GR.updatews()
    end
end

function gr_record(f::Function, filename::String, scene::Scene, iter)
    ext = uppercase(splitext(filename)[2][2:end])
    @assert ext in ("GIF", "MOV", "MP4", "WEBM", "OGG") """
    Extension of file is incorrect!  Expected one of (\"GIF\", \"MOV\", \"MP4\", \"WEBM\", \"OGG\").
    Found $ext.
    """
    withenv("GKS_WSTYPE" => uppercase(ext), "GKS_FILEPATH" => filename) do
        for i in iter
            GR.clearws()
            f(i)
            draw(scene)
        end
    end
end
