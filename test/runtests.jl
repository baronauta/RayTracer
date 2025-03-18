using RayTracer
using Test

import ColorTypes

@testset "Colors" begin
    c1 = ColorTypes.RGB{Float32}(0.1, 0.2, 0.3)
    c2 = ColorTypes.RGB{Float32}(0.4, 0.5, 0.6)
    @test c1 ≈ ColorTypes.RGB{Float32}(0.1, 0.2, 0.3)
    @test !(c1 ≈ c2)
    @test c1 + c2 ≈ ColorTypes.RGB{Float32}(0.5, 0.7, 0.9)
    @test 2 * c1 ≈ ColorTypes.RGB{Float32}(0.2, 0.4, 0.6)
    @test c1 * c2 ≈ ColorTypes.RGB{Float32}(0.04, 0.1, 0.18)
end


@testset "HdrImage" begin
    height = 6
    width = 9
    img = HdrImage(height, width)
    @test img.height == height
    @test img.width == width
    x = 5
    y = 7
    c = ColorTypes.RGB{Float32}(0.1, 0.2, 0.3)
    set_pixel!(img, x, y, c)
    @test img.pixels[x,y] ≈ c
    @test c ≈ get_pixel(img, x, y)
end
