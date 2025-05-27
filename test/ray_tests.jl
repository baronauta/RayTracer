@testset "Ray" begin
    # ≈
    ray1 = Ray(Point(1.0, 2.0, 3.0), Vec(5.0, 4.0, -1.0))
    ray2 = Ray(Point(1.0, 2.0, 3.0), Vec(5.0, 4.0, -1.0))
    ray3 = Ray(Point(1.0, 2.0, 3.0), Vec(3.0, 9.0, 4.0))
    ray4 = Ray(Point(5.0, 1.0, 4.0), Vec(5.0, 4.0, -1.0))
    @test ray1 ≈ ray2
    @test !(ray1 ≈ ray3)
    @test !(ray1 ≈ ray4)
    # at method
    ray = Ray(Point(1.0, 2.0, 4.0), Vec(4.0, 2.0, 1.0))
    RayTracer.at(ray, 0.0) ≈ ray.origin
    RayTracer.at(ray, 1.0) ≈ Point(5.0, 4.0, 5.0)
    RayTracer.at(ray, 2.0) ≈ Point(9.0, 6.0, 6.0)
    # Ray transformation
    ray = Ray(Point(1.0, 2.0, 3.0), Vec(6.0, 5.0, 4.0))
    transformation = translation(Vec(10.0, 11.0, 12.0)) * rotation_x(90.0)
    newray = RayTracer.transform(ray, transformation)
    @test newray.origin ≈ Point(11.0, 8.0, 14.0)
    @test newray.dir ≈ Vec(6.0, -4.0, 5.0)
end
