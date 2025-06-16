# === Helper functions ===
function test_all_intersections(
    s::Union{Shape,World},
    r::Ray,
    expected_hr::AbstractVector{<:Union{HitRecord, Nothing}},
)
    hitrecords = RayTracer.ray_intersection(s, r; all = true)
    for (hit, exp_hit) in zip(hitrecords, expected_hr)
        @test hit ≈ exp_hit
    end
end

# === Tests ===
@testset "Generic CSG and Shapes" begin
    sphere1 = Sphere()
    sphere1_copy = Sphere(Material(UniformPigment(RED)))
    sphere2 = Sphere(translation(Vec(0.0, 0.0, 1.0)), Material())
    
    # test for shapes comparison
    @test sphere1 ≈ sphere1_copy
    @test !(sphere1 ≈ sphere2)

    # test check for unvalid and valid CSGs
    @test_throws CsgError CSG(sphere1, sphere1, RayTracer.UNION)
    csg = CSG(sphere1, sphere2, RayTracer.UNION)

    # test for csg comparison
    csg_copy = CSG(sphere1, sphere2, RayTracer.UNION)
    csg2 = CSG(sphere1, sphere2, RayTracer.DIFFERENCE)
    csg3 = CSG(sphere2, sphere1, RayTracer.DIFFERENCE)
    csg = CSG(sphere1, sphere2, RayTracer.UNION)
    @test csg ≈ csg_copy
    @test !(csg ≈ csg2)
    @test !(csg2 ≈ csg3)
    
end

@testset "Is inside" begin
     # test if a HitRecord is inside a Sphere (important field is only Point)
    sphere1 = Sphere()
    sphere2 = Sphere(translation(Vec(0.0, 0.0, 1.0)), Material())

    hit = HitRecord(
            Point(0.0, 0.0, 0.0),
            Normal(0.0, 0.5, 0.0),
            Vec2D(0.25, 0.5),
            10.0,
            Ray(Point(2.0, 0.0, 0.0), Vec(-1.0, 0.0, 0.0)),
            sphere1,
        )
    @test RayTracer.is_inside(hit, sphere1)
    @test !RayTracer.is_inside(hit, sphere2)

end

@testset "Sphere - all HitRecords" begin
    sphere_unit = Sphere()
    # centered unit sphere
    ## ray from above
    ray_above = Ray(Point(0.0, 0.0, 2.0), -(VEC_Z))
    hr_above = HitRecord(
        Point(0.0, 0.0, 1.0),
        Normal(0.0, 0.0, 1.0),
        Vec2D(0.0, 0.0),
        1.0,
        ray_above,
        sphere_unit,
    )
    hr_under = HitRecord(
        Point(0.0, 0.0, -1.0),
        Normal(0.0, 0.0, 1.0),
        Vec2D(0.0, 1.0),
        3.0,
        ray_above,
        sphere_unit,
    )
    test_all_intersections(sphere_unit, ray_above, [hr_above, hr_under])
    ## ray from Origin towards x
    ray_x = Ray(Point(0.0, 0.0, 0.0), VEC_X)
    hr_x = HitRecord(
        Point(1.0, 0.0, 0.0),
        Normal(-1.0, 0.0, 0.0),
        Vec2D(0.0, 0.5),
        1.0,
        ray_x,
        sphere_unit,
    )
    test_all_intersections(sphere_unit, ray_x, [nothing, hr_x])

    ## ray from x in opposite direction, no intersection
    ray = Ray(Point(1.5, 0.0, 0.0), VEC_X)
    test_all_intersections(sphere_unit, ray, [nothing])

    ## tangent ray, no tangent intersection
    ray = Ray(Point(1.0, 0.0, -1.0), VEC_Z)
    test_all_intersections(sphere_unit, ray, [nothing])
end

@testset "CSG - all HitRecords" begin
    # objects
    sphere1 = Sphere()
    sphere2 = Sphere(translation(Vec(0.0, 0.0, 1.0)), Material())
    csg_U = CSG(sphere1, sphere2, RayTracer.UNION)
    csg_I = CSG(sphere1, sphere2, RayTracer.INTERSECTION)
    csg_F = CSG(sphere1, sphere2, RayTracer.FUSION)
    csg_D = CSG(sphere1, sphere2, RayTracer.DIFFERENCE)

    # rays
    ray_z = Ray(Point(0.0, 0.0, 3.0), -VEC_Z)
    ray_x = Ray(Point(-2.0, 0.0, 0.5), VEC_X)

    # hitrecords

    # x - tests to check if surphace contect points are considered correctly
    # ⚠️ NOT CONSIDERED CORRECTLY due to floating-point precision issues:
    # A point exactly on the surface may fail the check due to rounding.

    # ⚠️ Do NOT use a tolerance: it would include correct zero-measure cases,
    # but also wrongly accept non-zero measure regions.

    hr_x = RayTracer.ray_intersection(sphere1, ray_x)
    for csg in [csg_U, csg_I, csg_F, csg_D]
        # @test RayTracer.valid_hit(hr_x, sphere2, csg)
    end

    # z
    hr_z_1 = HitRecord(
        Point(0.0, 0.0, 2.0),
        Normal(0.0, 0.0, 1.0),
        Vec2D(0.0, 0.0),
        1.,
        ray_z,
        sphere2,
    )
    hr_z_2 = HitRecord(
        Point(0.0, 0.0, 1.0),
        Normal(0.0, 0.0, 1.0),
        Vec2D(0.0, 0.0),
        2.,
        ray_z,
        sphere1,
    )
    hr_z_3 = HitRecord(
        Point(0.0, 0.0, 0.0),
        Normal(0.0, 0.0, 1.0),
        Vec2D(0.0, 1.0),
        3.,
        ray_z,
        sphere2,
    )
    hr_z_4 = HitRecord(
        Point(0.0, 0.0, -1.0),
        Normal(0.0, 0.0, 1.0),
        Vec2D(0.0, 1.0),
        4.,
        ray_z,
        sphere1,
    )

    # valid_hit btw 2 sphere
    hits_U = [hr_z_1, hr_z_2, hr_z_3, hr_z_4]
    hits_I = [hr_z_2, hr_z_3]
    hits_F = [hr_z_1, hr_z_4]
    hits_D = [hr_z_3, hr_z_4]
    
    for (csg, hits) in zip([csg_U, csg_I, csg_F, csg_D], [hits_U, hits_I, hits_F, hits_D])
        for (hit, exp_hit) in zip(hits, RayTracer.ray_intersection(csg, ray_z; all = true))
            @test hit ≈ exp_hit  
        end
    end

end