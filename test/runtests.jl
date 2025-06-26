include("setup.jl")

@testset "All Tests" begin
    include("colors_tests.jl")
    include("hdrimage_tests.jl")
    include("io_tests.jl")
    include("tonemapping_tests.jl")
    include("geometry_tests.jl")
    include("ray_tests.jl")
    include("camera_tests.jl")
    include("shapes_tests.jl")
    include("pcg_tests.jl")
    include("material_tests.jl")
    include("csg_tests.jl")
    include("render_tests.jl")
    include("lexer_tests.jl")
    include("parser_tests.jl")

end

# not make a long expression of all tests passed.
nothing 