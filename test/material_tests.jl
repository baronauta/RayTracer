@testset "Pigments" begin

    @testset "UniformPigment" begin
        color = RGB(1.0, 2.0, 3.0)
        pigment = UniformPigment(color)

        @test RayTracer.get_color(pigment, Vec2D(0.0, 0.0)) ≈ color
        @test RayTracer.get_color(pigment, Vec2D(1.0, 0.0)) ≈ color
        @test RayTracer.get_color(pigment, Vec2D(0.0, 1.0)) ≈ color
        @test RayTracer.get_color(pigment, Vec2D(1.0, 1.0)) ≈ color
    end
end