@testset "Pigments" begin

    @testset "UniformPigment" begin
        color = RGB(1.0, 2.0, 3.0)
        pigment = UniformPigment(color)

        @test RayTracer.get_color(pigment, Vec2D(0.0, 0.0)) ≈ color
        @test RayTracer.get_color(pigment, Vec2D(1.0, 0.0)) ≈ color
        @test RayTracer.get_color(pigment, Vec2D(0.0, 1.0)) ≈ color
        @test RayTracer.get_color(pigment, Vec2D(1.0, 1.0)) ≈ color
    end

    @testset "CheckeredPigment" begin
        color1 = RGB(1.0, 2.0, 3.0)
        color2 = RGB(10.0, 20.0, 30.0)
        pigment = CheckeredPigment(color1, color2, 2)

        @test RayTracer.get_color(pigment, Vec2D(0.25, 0.25)) ≈ color1
        @test RayTracer.get_color(pigment, Vec2D(0.75, 0.25)) ≈ color2
        @test RayTracer.get_color(pigment, Vec2D(0.25, 0.75)) ≈ color2
        @test RayTracer.get_color(pigment, Vec2D(0.75, 0.75)) ≈ color1
    end

    @testset "ImagePigment" begin
        img = HdrImage(2, 2)
        RayTracer.set_pixel!(img, 1, 1, RGB(1.0, 2.0, 3.0))
        RayTracer.set_pixel!(img, 2, 1, RGB(2.0, 3.0, 1.0))
        RayTracer.set_pixel!(img, 1, 2, RGB(2.0, 1.0, 3.0))
        RayTracer.set_pixel!(img, 2, 2, RGB(3.0, 2.0, 1.0))

        pigment = ImagePigment(img)
        @test RayTracer.get_color(pigment, Vec2D(0.0, 0.0)) ≈ (RGB(1.0, 2.0, 3.0))
        @test RayTracer.get_color(pigment, Vec2D(1.0, 0.0)) ≈ (RGB(2.0, 3.0, 1.0))
        @test RayTracer.get_color(pigment, Vec2D(0.0, 1.0)) ≈ (RGB(2.0, 1.0, 3.0))
        @test RayTracer.get_color(pigment, Vec2D(1.0, 1.0)) ≈ (RGB(3.0, 2.0, 1.0))
    end

end


@testset "BRDFs" begin
    @testset "SpecularBRDF" begin
        # Test direciton for scatter_ray
        # A ray along the x=0 plane hit the z=0 plane mirror,
        # with an angle of 30° from the normal, expect an output direction with 30° from normal but with z-dir inverted
        pcg = RayTracer.RayTracer.PCG()
        incoming_dir = Vec(0.0, 0.5, -(sqrt(3)/2))
        expect_dir = Vec(0.0, 0.5, (sqrt(3)/2))
        interaction_point = Point(0.,0.,0.)
        normal = Normal(0.,0.,10.) # to be normalized
        depth = 1
        final_ray = RayTracer.scatter_ray( SpecularBRDF(), pcg, incoming_dir, interaction_point, normal, depth)
        @test expect_dir ≈ final_ray.dir
    end
end