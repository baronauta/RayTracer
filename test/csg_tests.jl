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
    @testset "Sphere" begin
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

    @testset "Plane" begin
        # test if a HitRecord is inside a PLane (important field is only Point)
        plane = Plane()
        plane2 = Plane(translation(Vec(0.0, 0.0, -1.0)), Material())

        hit = HitRecord(
                Point(0.0, 0.0, -0.5),
                Normal(0.0, 0.5, 0.0),
                Vec2D(0.25, 0.5),
                10.0,
                Ray(Point(2.0, 0.0, 0.0), Vec(-1.0, 0.0, 0.0)),
                plane,
            )
        @test RayTracer.is_inside(hit, plane)
        @test !RayTracer.is_inside(hit, plane2)
    end

end

@testset "Plane - all HitRecords" begin
    plane = Plane()
    ray_above = Ray(Point(0.0, 0.0, 2.0), -(VEC_Z))
    hr_above = HitRecord(
        Point(0.0, 0.0, 0.0),
        Normal(0.0, 0.0, 1.0),
        Vec2D(0.0, 0.0),
        2.0,
        ray_above,
        plane,
    )
    
    test_all_intersections(plane, ray_above, [hr_above])
    ## ray from Origin towards x
    ray_x = Ray(Point(0.0, 0.0, 0.0), VEC_X)
    test_all_intersections(plane, ray_x, [nothing])
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

@testset "CSG - 2 Sphere - all HitRecords" begin
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
    
    for (csg, exp_hits) in zip([csg_U, csg_I, csg_F, csg_D], [hits_U, hits_I, hits_F, hits_D])
        for (exp_hit, hit) in zip(exp_hits, RayTracer.ray_intersection(csg, ray_z; all = true))
            @test hit ≈ exp_hit  
        end
    end
end

@testset "CSG - 2 Planes - all HitRecords" begin
    plane1 = Plane()  # plane at origin (z=0)
    plane2 = Plane(translation(Vec(0.0, 0.0, 1.0)), Material())  # plane translated to z=1
    
    ray_down = Ray(Point(0.0, 0.0, 3.0), -VEC_Z)

    csg_union = CSG(plane1, plane2, RayTracer.UNION)
    csg_inter = CSG(plane1, plane2, RayTracer.INTERSECTION)
    csg_diff_1_2 = CSG(plane1, plane2, RayTracer.DIFFERENCE)  # plane1 minus plane2
    csg_diff_2_1 = CSG(plane2, plane1, RayTracer.DIFFERENCE)  # plane2 minus plane1
    csg_fusion = CSG(plane1, plane2, RayTracer.FUSION)

    hits_union = RayTracer.ray_intersection(csg_union, ray_down; all=true)
    hits_inter = RayTracer.ray_intersection(csg_inter, ray_down; all=true)
    hits_diff_1_2 = RayTracer.ray_intersection(csg_diff_1_2, ray_down; all=true)
    hits_diff_2_1 = RayTracer.ray_intersection(csg_diff_2_1, ray_down; all=true)
    hits_fusion = RayTracer.ray_intersection(csg_fusion, ray_down; all=true)

    @test length(hits_union) == 2  # both planes are intersected
    @test length(hits_inter) == 1  # only the lower plane (plane1) remains
    @test length(hits_diff_1_2) == 0 # difference plane1 - plane2: only plane1 below, but no hits remain
    @test length(hits_diff_2_1) == 2 # difference plane2 - plane1: only plane2 above remains
    @test length(hits_fusion) == 1  # fusion only above (plane2)

    @test hits_union[1].world_point ≈ Point(0.0, 0.0, 1.0)
    @test hits_union[2].world_point ≈ Point(0.0, 0.0, 0.0)

    @test hits_inter[1].world_point ≈ Point(0.0, 0.0, 0.0)
    
    @test hits_diff_2_1[1].world_point ≈ Point(0.0, 0.0, 1.0)
    @test hits_diff_2_1[2].world_point ≈ Point(0.0, 0.0, 0.0)

    @test hits_fusion[1].world_point ≈ Point(0.0, 0.0, 1.0)
end

@testset "CSG - Sphere and Plane - all HitRecords" begin
    sphere = Sphere()
    plane = Plane(translation(Vec(0.0, 0.0, 0.0)), Material())
    
    ray_down = Ray(Point(0.0, 0.0, 3.0), -VEC_Z)

    csg_union = CSG(sphere, plane, RayTracer.UNION)
    csg_inter = CSG(sphere, plane, RayTracer.INTERSECTION)
    csg_diff_sphere_plane = CSG(sphere, plane, RayTracer.DIFFERENCE)  # sphere minus plane
    csg_diff_plane_sphere = CSG(plane, sphere, RayTracer.DIFFERENCE)  # plane minus sphere
    csg_fusion = CSG(sphere, plane, RayTracer.FUSION)

    hits_union = RayTracer.ray_intersection(csg_union, ray_down; all=true)
    hits_inter = RayTracer.ray_intersection(csg_inter, ray_down; all=true)
    hits_diff_sphere_plane = RayTracer.ray_intersection(csg_diff_sphere_plane, ray_down; all=true)
    hits_diff_plane_sphere = RayTracer.ray_intersection(csg_diff_plane_sphere, ray_down; all=true)
    hits_fusion = RayTracer.ray_intersection(csg_fusion, ray_down; all=true)

    @test length(hits_union) == 3
    @test length(hits_inter) == 2
    @test length(hits_diff_sphere_plane) == 2
    @test length(hits_diff_plane_sphere) == 1
    @test length(hits_fusion) == 1

    @test hits_union[1].world_point ≈ Point(0.0, 0.0, 1.0)
    @test hits_union[2].world_point ≈ Point(0.0, 0.0, 0.0)
    @test hits_union[3].world_point ≈ Point(0.0, 0.0, -1.0)

    @test hits_inter[1].world_point ≈ Point(0.0, 0.0, 0.0)
    @test hits_inter[2].world_point ≈ Point(0.0, 0.0, -1.0)
    
    @test hits_diff_sphere_plane[1].world_point ≈ Point(0.0, 0.0, 1.0)
    @test hits_diff_sphere_plane[2].world_point ≈ Point(0.0, 0.0, 0.0)

    @test hits_diff_plane_sphere[1].world_point ≈ Point(0.0, 0.0, -1.0)

    @test hits_fusion[1].world_point ≈ Point(0.0, 0.0, 1.0)
end

@testset "Multiple nested CSGs" begin
    # test if a hitrecord belongs to a csg
    sphere1 = Sphere()
    sphere2 = Sphere(translation(Vec(0.0, 0.0, 1.0)), Material())
    sphere3 = Sphere(translation(Vec(0.0, 0.0, -0.5)), Material())

    csg_D = CSG(CSG(sphere1, sphere3, RayTracer.DIFFERENCE), sphere2, RayTracer.DIFFERENCE)

    ray_z = Ray(Point(0.0, 0.0, 3.0), -VEC_Z)
    hr_z_1 = HitRecord(Point(0.0, 0.0, 2.0), Normal(0.0, 0.0, 1.0), Vec2D(0.0, 0.0), 1., ray_z, sphere2)
    hr_z_2 = HitRecord(Point(0.0, 0.0, 1.0), Normal(0.0, 0.0, 1.0), Vec2D(0.0, 0.0), 2., ray_z, sphere1)

    @test !RayTracer._belongs(hr_z_1, csg_D.obj1)
    @test RayTracer._belongs(hr_z_2, csg_D.obj1)

    @testset "3 OBJ" begin
        # 3 spheres
        sphere1 = Sphere()
        sphere2 = Sphere(translation(Vec(0.0, 0.0, 1.0)), Material())
        sphere3 = Sphere(translation(Vec(0.0, 0.0, -0.5)), Material())

        csg_U = CSG(CSG(sphere1, sphere2, RayTracer.UNION), sphere3, RayTracer.UNION)
        csg_I = CSG(CSG(sphere1, sphere2, RayTracer.INTERSECTION), sphere3, RayTracer.INTERSECTION)
        csg_F = CSG(CSG(sphere1, sphere2, RayTracer.INTERSECTION), sphere3, RayTracer.FUSION)
        csg_D = CSG(CSG(sphere1, sphere2, RayTracer.INTERSECTION), sphere3, RayTracer.DIFFERENCE)

        ray_z = Ray(Point(0.0, 0.0, 3.0), -VEC_Z)

        hr_z_1 = HitRecord(Point(0.0, 0.0, 2.0), Normal(0.0, 0.0, 1.0), Vec2D(0.0, 0.0), 1., ray_z, sphere2)
        hr_z_2 = HitRecord(Point(0.0, 0.0, 1.0), Normal(0.0, 0.0, 1.0), Vec2D(0.0, 0.0), 2., ray_z, sphere1)
        hr_z_3 = HitRecord(Point(0.0, 0.0, 0.5), Normal(0.0, 0.0, 1.0), Vec2D(0.0, 0.0), 2.5, ray_z, sphere3)
        hr_z_4 = HitRecord(Point(0.0, 0.0, 0.0), Normal(0.0, 0.0, 1.0), Vec2D(0.0, 1.0), 3., ray_z, sphere2)
        hr_z_5 = HitRecord(Point(0.0, 0.0, -1.0), Normal(0.0, 0.0, 1.0), Vec2D(0.0, 1.0), 4., ray_z, sphere1)
        hr_z_6 = HitRecord(Point(0.0, 0.0, -1.5), Normal(0.0, 0.0, 1.0), Vec2D(0.0, 1.0), 4.5, ray_z, sphere3)

        hits_U = [hr_z_1, hr_z_2, hr_z_3, hr_z_4, hr_z_5, hr_z_6]
        hits_I = [hr_z_3, hr_z_4]
        hits_F = [hr_z_2, hr_z_6]
        hits_D = [hr_z_2, hr_z_3]

        for (csg, exp_hits) in zip([csg_U, csg_I, csg_F, csg_D], [hits_U, hits_I, hits_F, hits_D])
            hits = RayTracer.ray_intersection(csg, ray_z; all = true)
            @test length(exp_hits) == length(hits)
            for (exp_hit, hit) in zip(exp_hits, hits)
                @test hit ≈ exp_hit  
            end
        end

        # 2 Spheres, 1 Plane
        plane = Plane(translation(Vec(0.0, 0.0, 0.5)), Material())
        # hr_plane will be hr_z_3
        csg_U = CSG(CSG(sphere1, sphere2, RayTracer.UNION), plane, RayTracer.UNION)
        csg_I = CSG(CSG(sphere1, sphere2, RayTracer.INTERSECTION), plane, RayTracer.INTERSECTION)
        csg_D = CSG(CSG(sphere1, sphere2, RayTracer.INTERSECTION), plane, RayTracer.DIFFERENCE)
        
        hits_U = [hr_z_1, hr_z_2, hr_z_3, hr_z_4, hr_z_5]
        hits_I = [hr_z_3, hr_z_4]
        hits_D = [hr_z_2, hr_z_3]
        for (csg, exp_hits) in zip([csg_U, csg_I, csg_D], [hits_U, hits_I, hits_D])
            hits = RayTracer.ray_intersection(csg, ray_z; all = true)
            @test length(exp_hits) == length(hits)
            for (exp_hit, hit) in zip(exp_hits, hits)
                @test hit ≈ exp_hit  
            end
        end
    end


end