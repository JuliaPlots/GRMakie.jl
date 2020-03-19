using GRMakie

using AbstractPlotting, MakieGallery

using Test

include("saving.jl")
# 
# database = MakieGallery.load_database(["short_tests.jl"]);
#
# filter!(database) do example
#     !("3d" ∈ example.tags) &&
#     !("heatmap" in entry.tags) &&
#     !("image" in entry.tags) &&
#     !(lowercase(entry.title) ∈ (
#         "arrows on hemisphere", "cobweb plot", "lots_of_heatmaps",
#         "streamplot animation", "test heatmap + image overlap", "lots of heatmaps"
#     ))
# end
#
