# === Helper functions ===
function test_intersection(
    s::Union{Shape,World},
    r::Ray,
    expected_hr::Union{HitRecord,Nothing},
)
    hitrecord = RayTracer.ray_intersection(s, r)
    @test hitrecord ≈ expected_hr
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

    @testset "Cube" begin
        cube = Cube()
        # centered unit cube
        ## ray from above
        ray_above = Ray(Point(0.5, 0.5, 2.0), -(VEC_Z))
        hr_above = HitRecord(
            Point(0.5, 0.5, 1.0),
            Normal(0.0, 0.0, 1.0),
            Vec2D(5/8, 0.5),
            1.0,
            ray_above,
            cube,
        )
        test_intersection(cube, ray_above, hr_above)

        ## ray towards x, 1 intersection
        ray_x = Ray(Point(0.5, 0.5, 0.5), VEC_X)
        hr_x = HitRecord(
            Point(1.0, 0.5, 0.5),
            Normal(-1.0, 0.0, 0.0),
            Vec2D(3/8, 0.5),
            0.5,
            ray_x,
            cube,
        )
        test_intersection(cube, ray_x, hr_x)

        ## ray from x in opposite direction, no intersection
        test_intersection(cube, Ray(Point(1.5, 0.5, 0.5), VEC_X), nothing)

        ## tangent ray
        ray = Ray(Point(2.0, 0.0, 0.0), -VEC_X)
        hr = HitRecord(
            Point(1.0, 0.0, 0.0),
            Normal(1.0, 0.0, 0.0),
            Vec2D(1/4, 1/3),
            1.,
            ray,
            cube,
        )
        test_intersection(cube, ray, hr)

        ## ∦ to any axis, general case
        ray = Ray(Point(1.5, 2.0, 1.5), Vec(-1.0, -1.0, -1.0))
        hr = HitRecord(
            Point(0.5, 1.0, 0.5),
            Normal(0.0, 1.0, 0.0),
            Vec2D(3/8, 5/6),
            1.,
            ray,
            cube,
        )
        test_intersection(cube, ray, hr)

        # cube translated
        cube = Cube(translation(Vec(-1.,-1.,-1.,)), Material())
        ## ray from above
        ray_above = Ray(Point(-0.5, -0.5, 1.0), -(VEC_Z))
        hr_above = HitRecord(
            Point(-0.5, -0.5, 0.0),
            Normal(0.0, 0.0, 1.0),
            Vec2D(5/8, 0.5),
            1.0,
            ray_above,
            cube,
        )
        test_intersection(cube, ray_above, hr_above)

        # cube scaled
        cube = Cube(scaling(2.,2.,2.), Material())
        ## ray from above
        ray_above = Ray(Point(1., 1., 3.), -(VEC_Z))
        hr_above = HitRecord(
            Point(1.0, 1.0, 2.0),
            Normal(0.0, 0.0, 0.5),
            Vec2D(5/8, 0.5),
            1.0,
            ray_above,
            cube,
        )
        test_intersection(cube, ray_above, hr_above)

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
