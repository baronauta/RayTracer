# === Helper functions ===
function test_intersection(
    s::Union{Shape,World},
    r::Ray,
    expected_hr::Union{HitRecord,Nothing},
)
    hitrecord = RayTracer.ray_intersection(s, r)
    @test hitrecord ≈ expected_hr
end

function test_all_intersections(
    s::Union{Shape,World},
    r::Ray,
    expected_hr::AbstractVector{<:Union{HitRecord, Nothing}},
)
    hitrecords = RayTracer.all_ray_intersections(s, r)
    for (hit, exp_hit) in zip(hitrecords, expected_hr)
        @test hit ≈ exp_hit
    end
end

# === Tests ===
@testset "Shapes" begin

    @testset "Plane" begin
        plane_xy = Plane()
        # xy-plane and incoming orthogonal ray from above
        ray_above = Ray(Point(1.0, 2.0, 3.0), Vec(0.0, 0.0, -1.0))
        hr_above = HitRecord(
            Point(1.0, 2.0, 0.0),
            Normal(0.0, 0.0, 1.0),
            Vec2D(0.0, 0.0),
            3.0,
            ray_above,
            plane_xy,
        )
        test_intersection(plane_xy, ray_above, hr_above)
        # xy-plane and incoming 45° ray from below
        ray_diag = Ray(Point(1.0, 1.0, -1.0), Vec(-1.0, -1.0, 1.0))
        hr_diag = HitRecord(
            Point(0.0, 0.0, 0.0),
            Normal(0.0, 0.0, -1.0),
            Vec2D(0.0, 0.0),
            1.0,
            ray_diag,
            plane_xy,
        )
        test_intersection(plane_xy, ray_diag, hr_diag)
        # xy-plane and ray in x-direction: no intersection
        ray_x = Ray(Point(1.0, 2.0, 3.0), Vec(1.0, 0.0, 0.0))
        hr_x = nothing
        test_intersection(plane_xy, ray_x, hr_x)
        # xz-plane (y=0) and ray in y-direction: intersection;
        # test also 2D coordinates.
        ray_y = Ray(Point(0.1, -1.0, 0.0), Vec(0.0, 1.0, 0.0))
        plane_rotated = Plane(rotation_x(90), Material())
        hr_rotated = HitRecord(
            Point(0.1, 0.0, 0.0),
            Normal(0.0, -1.0, 0.0),
            Vec2D(0.1, 0.0),
            1.0,
            ray_y,
            plane_rotated,
        )
        test_intersection(plane_rotated, ray_y, hr_rotated)
        # Ray with origin (0,0,2) and direction (0,0,1):
        # xy-plane (z=0): no intersection
        # translated xy-plane (e.g. z=3): intersection
        ray_z = Ray(Point(0.0, 0.0, 2.0), Vec(0.0, 0.0, 1.0))
        hr_z0 = nothing
        plane_translated = Plane(translation(Vec(0.0, 0.0, 3.0)), Material())
        hr_z3 = HitRecord(
            Point(0.0, 0.0, 3.0),
            Normal(0.0, 0.0, -1.0),
            Vec2D(0.0, 0.0),
            1.0,
            ray_z,
            plane_translated,
        )
        test_intersection(plane_xy, ray_z, hr_z0)
        test_intersection(plane_translated, ray_z, hr_z3)
    end

    @testset "Sphere" begin
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
        test_intersection(sphere_unit, ray_above, hr_above)

        ## ray from x
        ray_x = Ray(Point(3.0, 0.0, 0.0), -(VEC_X))
        hr_x = HitRecord(
            Point(1.0, 0.0, 0.0),
            Normal(1.0, 0.0, 0.0),
            Vec2D(0.0, 0.5),
            2.0,
            ray_x,
            sphere_unit,
        )
        test_intersection(sphere_unit, ray_x, hr_x)

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
        test_intersection(sphere_unit, ray_x, hr_x)

        ## ray from x in opposite direction, no intersection
        ray = Ray(Point(1.5, 0.0, 0.0), VEC_X)
        hr = nothing
        test_intersection(sphere_unit, ray, hr)

        ## tangent ray, no tangent intersection
        ray = Ray(Point(1.0, 0.0, -1.0), VEC_Z)
        hr = nothing
        test_intersection(sphere_unit, ray, hr)

        # translated unit sphere
        ## x_transltion, ray from above
        sphere = Sphere(translation(Vec(10.0, 0.0, 0.0)), Material())
        ray = Ray(Point(10.0, 0.0, 3.0), -(VEC_Z))
        hr = HitRecord(
            Point(10.0, 0.0, 1.0),
            Normal(0.0, 0.0, 1.0),
            Vec2D(0.0, 0.0),
            2.0,
            ray,
            sphere,
        )
        test_intersection(sphere, ray, hr)

        ## x_transltion, ray from above, no intersections
        ## (want to test possible false intersection with untransformed sphere)
        sphere = Sphere(translation(Vec(10.0, 0.0, 0.0)), Material())
        ray = Ray(Point(0.0, 0.0, 3.0), -(VEC_Z))
        hr = nothing
        test_intersection(sphere, ray, hr)

        #rotated unit sphere 
        ## (tests for surface coordinates transformation)
        ### +45° z rotation, ray from x_pos (test u)
        sphere = Sphere(rotation_z(45), Material())
        ray = Ray(Point(14.0, 0.0, 0.0), -(VEC_X))
        hr = HitRecord(
            Point(1.0, 0.0, 0.0),
            Normal(1.0, 0.0, 0.0),
            Vec2D(0.875, 0.5), # wrong untransformed (u,v) = (0.0,0.5)
            13.0,
            ray,
            sphere,
        )
        test_intersection(sphere, ray, hr)
        ### +45° y rotation, ray from x_pos (test v)
        sphere = Sphere(rotation_y(45), Material())
        ray = Ray(Point(14.0, 0.0, 0.0), -(VEC_X))
        hr = HitRecord(
            Point(1.0, 0.0, 0.0),
            Normal(1.0, 0.0, 0.0),
            Vec2D(0.0, 0.25), # wrong untransformed (u,v) = (0.0,0.5)
            13.0,
            ray,
            sphere,
        )
        test_intersection(sphere, ray, hr)

        # *2 uniform scaling
        ## ray from y
        sphere = Sphere(scaling(2.0, 2.0, 2.0), Material())
        ray = Ray(Point(0.0, 12.0, 0.0), Vec(0.0, -1.0, 0.0))
        hr = HitRecord(
            Point(0.0, 2.0, 0.0),
            Normal(0.0, 0.5, 0.0),
            Vec2D(0.25, 0.5),
            10.0,
            ray,
            sphere,
        )
        test_intersection(sphere, ray, hr)
    end
end

@testset "CSG" begin
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
        @test RayTracer.is_inside(hit, sphere1, true)
        @test !RayTracer.is_inside(hit, sphere2, false)
        @test RayTracer.is_inside(hit, sphere2, true)

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
            for (hit, exp_hit) in zip(hits, RayTracer.all_ray_intersections(csg, ray_z))
                @test hit ≈ exp_hit  
            end
        end

    end
end

@testset "World" begin
    # one setup for all tests
    # Shapes
    sphere1 = Sphere(translation(Vec(0.0, 0.0, 5.0)), Material())
    sphere2 = Sphere(translation(Vec(0.0, 0.0, 1.5)), Material())
    shapes = [sphere1, sphere2]
    world = World(shapes)
    # adding plane
    plane = Plane()
    RayTracer.add!(world, plane)
    # rays
    ray_z1 = Ray(Point(0.0, 0.0, 10.0), Vec(0.0, 0.0, -1.0))
    ray_z2 = Ray(Point(0.0, 0.0, -10.0), Vec(0.0, 0.0, 1.0))
    # HitRecords
    hr1 = HitRecord( # hit only sphere1 into north pole
        Point(0.0, 0.0, 6.0),
        Normal(0.0, 0.0, 1.0),
        Vec2D(0.0, 0.0),
        4.0,
        ray_z1,
        sphere1,
    )
    hr2 = HitRecord( # hit only the plane into the origin
        Point(0.0, 0.0, 0.0),
        Normal(0.0, 0.0, -1.0),
        Vec2D(0.0, 0.0),
        10.0,
        ray_z2,
        plane,
    )
    # tests
    test_intersection(world, ray_z1, hr1)
    test_intersection(world, ray_z2, hr2)
end
