database = MakieGallery.load_database(["short_tests.jl"]);

filter!(database) do example
    !("3d" ∈ example.tags) &&
    !("heatmap" in example.tags) &&
    !("image" in example.tags) &&
    !(lowercase(example.title) ∈ (
        "arrows on hemisphere", "cobweb plot", "lots_of_heatmaps",
        "streamplot animation", "test heatmap + image overlap", "lots of heatmaps"
    ))
end

format_save_path = joinpath(@__DIR__, "test_format")
isdir(format_save_path) && rm(format_save_path, recursive = true)
mkpath(format_save_path)
savepath(uid, fmt) = joinpath(format_save_path, "$uid.$fmt")

@testset "Saving formats" begin
    for fmt in ("png", "jpeg", "tiff", "bmp", "svg", "pdf", "tex", "eps")
        for example in database
            @test try
                save(savepath(example.unique_name, fmt), MakieGallery.eval_example(example))
                true
            catch e
                @warn "Saving $(example.unique_name) in format `$fmt` failed!" exception=(e, Base.catch_backtrace())
                false
            end
        end
    end
end
