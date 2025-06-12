@testset "ToneMapping" begin
    # Luminosity
    col1 = RGB(10.0, 3.0, 2.0)
    @test RayTracer.luminosity(col1, mean_type = :max_min) ≈ 6
    @test RayTracer.luminosity(col1, mean_type = :arithmetic) ≈ 5
    @test RayTracer.luminosity(col1, mean_type = :weighted, weights = [1, 1, 1]) ≈ 5
    @test RayTracer.luminosity(col1, mean_type = :weighted, weights = [1, 2, 5]) ≈ 3.25
    @test isapprox(
        RayTracer.luminosity(col1, mean_type = :distance),
        10.6301;
        atol = 0.0001,
    )
    # Logarithmic average
    # Image for test
    img = HdrImage(2, 1)
    RayTracer.set_pixel!(img, 1, 1, RGB(5.0, 10.0, 15.0)) # Luminosity (min-max): 10.0
    RayTracer.set_pixel!(img, 2, 1, RGB(500.0, 1000.0, 1500.0)) # Luminosity (min-max): 1000.0
    @test RayTracer.log_average(img, mean_type = :max_min, delta = 0.0) ≈ 100.0
    # Test that delta helps in avoiding log singularity when a pixel is black
    img = HdrImage(2, 1)
    RayTracer.set_pixel!(img, 1, 1, RGB(50.0, 100.0, 150.0)) # Luminosity (min-max): 100.0
    @test RayTracer.log_average(img, mean_type = :max_min) ≈ 1e-4
    # Normalization
    # Image for test
    img = HdrImage(2, 1)
    RayTracer.set_pixel!(img, 1, 1, RGB(5.0, 10.0, 15.0))
    RayTracer.set_pixel!(img, 2, 1, RGB(500.0, 1000.0, 1500.0))
    RayTracer.normalize_image!(img, a = 1000.0, lumi = 100.0)
    @test RayTracer.get_pixel(img, 1, 1) ≈ RGB(0.5e2, 1.0e2, 1.5e2)
    @test RayTracer.get_pixel(img, 2, 1) ≈ RGB(0.5e4, 1.0e4, 1.5e4)
    RayTracer.normalize_image!(img, a = 1000.0)
    @test RayTracer.get_pixel(img, 1, 1) ≈ RGB(0.5e2, 1.0e2, 1.5e2)
    @test RayTracer.get_pixel(img, 2, 1) ≈ RGB(0.5e4, 1.0e4, 1.5e4)
    # Clamp image
    # Image for test
    img = HdrImage(2, 1)
    RayTracer.set_pixel!(img, 1, 1, RGB(5.0, 10.0, 15.0))
    RayTracer.set_pixel!(img, 2, 1, RGB(500.0, 1000.0, 1500.0))
    # Just check that the R/G/B values are within the expected boundaries
    RayTracer.clamp_image!(img)
    for pixel in img.pixels
        @test 0 <= pixel.r <= 1
        @test 0 <= pixel.g <= 1
        @test 0 <= pixel.b <= 1
    end
end

@testset "ToneMapping - Exceptions" begin

    @testset "Wrong method" begin
        err_thrown = false
        col1 = RGB(10.0, 3.0, 2.0)
        try
            _ = RayTracer.luminosity(col1, mean_type = :not_a_method)
        catch e
            if isa(e, ToneMappingError)
                err_thrown = true
            else
                rethrow(e)
            end
        end
        @test err_thrown
    end

    @testset "Wrong weigths lenght" begin
        err_thrown = false
        col1 = RGB(10.0, 3.0, 2.0)
        try
            _ = RayTracer.luminosity(col1, mean_type = :weighted, weights = [1, 1])

        catch e
            if isa(e, ToneMappingError)
                err_thrown = true
            else
                rethrow(e)
            end
        end
        @test err_thrown
    end

    @testset "Missing weights" begin
        err_thrown = false
        col1 = RGB(10.0, 3.0, 2.0)
        try
            _ = RayTracer.luminosity(col1, mean_type = :weighted)
        catch e
            if isa(e, ToneMappingError)
                err_thrown = true
            else
                rethrow(e)
            end
        end
        @test err_thrown
    end
end