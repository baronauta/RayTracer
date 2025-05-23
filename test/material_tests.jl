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
end