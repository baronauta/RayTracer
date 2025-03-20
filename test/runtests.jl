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
    @test RayTracer.color_to_string(c1) == "< r:0.1, g:0.2, b:0.3 >"
end

@testset "HdrImage" begin
    width = 9
    height = 6
    img = HdrImage(width, height)
    @test img.height == height
    @test img.width == width
    x = 7
    y = 5
    c = ColorTypes.RGB{Float32}(0.1, 0.2, 0.3)
    RayTracer.set_pixel!(img, x, y, c)
    @test img.pixels[y, x] ≈ c
    @test c ≈ RayTracer.get_pixel(img, x, y)
end

@testset "I/O-Read" begin
    # Unit tests
    width = 128
    height = 256
    s1 = "$width $height"
    @test (width, height) == RayTracer._parse_img_size(s1)
    be = "+1.0"
    le = "-1.0"
    @test RayTracer._parse_endianness(be) == 1.
    @test RayTracer._parse_endianness(le) == -1.
    # Integration test
    

end
