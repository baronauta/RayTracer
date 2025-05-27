@testset "HdrImage" begin
    width = 9
    height = 6
    img = HdrImage(width, height)
    @test img.height == height
    @test img.width == width
    x = 7
    y = 5
    c = RayTracer.RGB(0.1, 0.2, 0.3)
    RayTracer.set_pixel!(img, x, y, c)
    @test img.pixels[y, x] ≈ c
    @test c ≈ RayTracer.get_pixel(img, x, y)
end
