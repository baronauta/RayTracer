# === Helper functions ===
function test_all_intersections(
    s::Union{Shape,World},
    r::Ray,
    expected_hr::AbstractVector{<:Union{HitRecord,Nothing}},
)
    hitrecords = RayTracer.ray_intersection(s, r; all = true)
    @test length(expected_hr) == length(hitrecords)
    for (hit, exp_hit) in zip(hitrecords, expected_hr)
        @test hit ≈ exp_hit
    end
end

function test_intersection(
    s::Union{Shape,World},
    r::Ray,
    expected_hr::Union{HitRecord,Nothing},
)
    hitrecord = RayTracer.ray_intersection(s, r)
    @test hitrecord ≈ expected_hr
end


# === Scene Definition ===

#! format: off

# Shapes
sphere1 = Sphere()
sphere2 = Sphere(translation(Vec(0.0, 0.0, 1.0)), Material())
sphere3 = Sphere(translation(Vec(0.0, 0.0, -0.5)), Material())
plane1 = Plane()
plane2 = Plane(translation(Vec(0.0, 0.0, 0.5)), Material())

# Rays
ray_z = Ray(Point(0.0, 0.0, 3.0), -VEC_Z)
ray_origin_x = Ray(Point(0.0, 0.0, 0.0), VEC_X)
hr_x = HitRecord(Point(1.0, 0.0, 0.0), Normal(-1.0, 0.0, 0.0), Vec2D(0.0, 0.5), 1.0, ray_origin_x, sphere1)

# HitRecords along z
hr_z_1 = HitRecord(Point(0.0, 0.0, 2.0), Normal(0.0, 0.0, 1.0), Vec2D(0.0, 0.0), 1.0, ray_z, sphere2)
hr_z_2 = HitRecord(Point(0.0, 0.0, 1.0), Normal(0.0, 0.0, 1.0), Vec2D(0.0, 0.0), 2.0, ray_z, sphere1)
hr_z_3 = HitRecord(Point(0.0, 0.0, 0.5), Normal(0.0, 0.0, 1.0), Vec2D(0.0, 0.0), 2.5, ray_z, sphere3)
hr_z_3_p = HitRecord(Point(0.0, 0.0, 0.5), Normal(0.0, 0.0, 1.0), Vec2D(0.0, 0.0), 2.5, ray_z, plane2)
hr_z_4 = HitRecord(Point(0.0, 0.0, 0.0), Normal(0.0, 0.0, 1.0), Vec2D(0.0, 1.0), 3.0, ray_z, sphere2)
hr_z_4_p = HitRecord(Point(0.0, 0.0, 0.0), Normal(0.0, 0.0, 1.0), Vec2D(0.0, 0.0), 3.0, ray_z, plane1)
hr_z_5 = HitRecord(Point(0.0, 0.0, -1.0), Normal(0.0, 0.0, 1.0), Vec2D(0.0, 1.0), 4.0, ray_z, sphere1)
hr_z_6 = HitRecord(Point(0.0, 0.0, -1.5), Normal(0.0, 0.0, 1.0), Vec2D(0.0, 1.0), 4.5, ray_z, sphere3)

#=               
ASCII Diagram Legend:
  X  → intersection point
  │  → direction of the ray (downward)
  ─  → plane
  .--~~--.  → stylized sphere boundary   │ray_z                                                          
                                         │                                                          
                                         │                                                          
                                         ▼                                                          
                                         │int1                                                     ─    
                                    . -- X~~ -- .                                                   
                                .-~      │        ~-.                                               
                               /         │           \                                              
                              /          │            \ sphere2                                            
                             |           │int2         |                                            
                             |      . -- X~~ -- .      |                                            
     plane2                  |  .-~      │        ~-.  |                                            
     ───────────────────────────────.─--─X~~─--─.─────────────────────────────────                  
                              /\.-~      │int3    ~-./\  sphere1                                           
     plane1 (x = 0)          | /`-.      │        .-'\ |                                            
     ─────────────────────────/──────────X────────────\───────────────────────────                  
                             |           │int4         |                                            
                             |\          │            /|                                            
                             | \         │           / |                                            
                              \ `-.      │int5     .-' /                                             
                               \    ~- . X__ . -~    /   sphere3                                           
                                `-.      │        .-'                                               
                                    ~- . X__ . -~                                                   
                                         │int6
=#

# === Tests ===
@testset "Generic CSG and Shapes" begin
    sphere1_copy = Sphere(Material(UniformPigment(RED)))

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
        
        # hit in the origin is inside sphere1 and outside sphere2
        
        @test RayTracer.is_inside(hr_z_4_p, sphere1)
        @test !RayTracer.is_inside(hr_z_4_p, sphere2)
    end

    @testset "Plane" begin
        # test if a HitRecord is inside a plane

        # hit in the origin is inside plane 2 and outside plane1

        @test RayTracer.is_inside(hr_z_4, plane2)
        @test !RayTracer.is_inside(hr_z_4_p, plane1)
    end

end

@testset "Plane - all HitRecords" begin

    # test plane 1 with 2 rays, ray_z (1 hit) and ray_origin_x (0 hit)
    # ray from z
    test_all_intersections(plane1, ray_z, [hr_z_4_p])

    ## ray from Origin towards x
    test_all_intersections(plane1, ray_origin_x, [nothing])
end

@testset "Sphere - all HitRecords" begin
    # unit sphere
    # ray from z, 2 intersections
    test_all_intersections(sphere1, ray_z, [hr_z_2, hr_z_5])

    ## ray from Origin towards x
    test_all_intersections(sphere1, ray_origin_x, [nothing, hr_x])

    ## ray from x in opposite direction, no intersection
    test_all_intersections(sphere1, Ray(Point(1.5, 0.0, 0.0), VEC_X), [nothing])

    ## tangent ray, no tangent intersection
    test_all_intersections(sphere1, Ray(Point(1.0, 0.0, -1.0), VEC_Z), [nothing])
end

@testset "CSG - 2 Sphere - all HitRecords" begin
    # union sphere and sphere in z=1
    # objects
    csg_U = CSG(sphere1, sphere2, RayTracer.UNION)
    csg_I = CSG(sphere1, sphere2, RayTracer.INTERSECTION)
    csg_F = CSG(sphere1, sphere2, RayTracer.FUSION)
    csg_D = CSG(sphere1, sphere2, RayTracer.DIFFERENCE)

    # x - tests to check if surphace contect points are considered correctly
    # ray_x = Ray(Point(-2.0, 0.0, 0.5), VEC_X)
    # ⚠️ NOT CONSIDERED CORRECTLY due to floating-point precision issues:
    # A point exactly on the surface may fail the check due to rounding.

    # ⚠️ Do NOT use a tolerance: it would include correct zero-measure cases,
    # but also wrongly accept non-zero measure regions.

    # hr_x = RayTracer.ray_intersection(sphere1, ray_x)
    # for csg in [csg_U, csg_I, csg_F, csg_D]
    #     @test RayTracer.valid_hit(hr_x, sphere2, csg)
    # end

    # z
    # valid_hit btw 2 sphere
    test_all_intersections(csg_U, ray_z, [hr_z_1, hr_z_2, hr_z_4, hr_z_5])
    test_all_intersections(csg_I, ray_z, [hr_z_2, hr_z_4])
    test_all_intersections(csg_F, ray_z, [hr_z_1, hr_z_5])
    test_all_intersections(csg_D, ray_z, [hr_z_4, hr_z_5])
end

@testset "CSG - 2 Planes - all HitRecords" begin
    # objects
    csg_union = CSG(plane1, plane2, RayTracer.UNION)
    csg_inter = CSG(plane1, plane2, RayTracer.INTERSECTION)
    csg_diff_1_2 = CSG(plane1, plane2, RayTracer.DIFFERENCE)  # plane1 minus plane2
    csg_diff_2_1 = CSG(plane2, plane1, RayTracer.DIFFERENCE)  # plane2 minus plane1
    csg_fusion = CSG(plane1, plane2, RayTracer.FUSION)

    test_all_intersections(csg_union, ray_z, [hr_z_3_p, hr_z_4_p])
    test_all_intersections(csg_inter, ray_z, [hr_z_4_p])
    test_all_intersections(csg_diff_1_2, ray_z, [nothing])  # nothing remains
    test_all_intersections(csg_diff_2_1, ray_z, [hr_z_3_p, hr_z_4_p])
    test_all_intersections(csg_fusion, ray_z, [hr_z_3_p])
end

@testset "CSG - Sphere and Plane - all HitRecords" begin
    # union sphere and default plane
    # objects
    csg_union = CSG(sphere1, plane1, RayTracer.UNION)
    csg_inter = CSG(sphere1, plane1, RayTracer.INTERSECTION)
    csg_diff_sphere_plane = CSG(sphere1, plane1, RayTracer.DIFFERENCE)  # sphere minus plane
    csg_diff_plane_sphere = CSG(plane1, sphere1, RayTracer.DIFFERENCE)  # plane minus sphere
    csg_fusion = CSG(sphere1, plane1, RayTracer.FUSION)

    test_all_intersections(csg_union, ray_z, [hr_z_2, hr_z_4_p, hr_z_5])
    test_all_intersections(csg_inter, ray_z, [hr_z_4_p, hr_z_5])
    test_all_intersections(csg_diff_sphere_plane, ray_z, [hr_z_2, hr_z_4_p])
    test_all_intersections(csg_diff_plane_sphere, ray_z, [hr_z_5])
    test_all_intersections(csg_fusion, ray_z, [hr_z_2])
end

@testset "Multiple nested CSGs" begin
    # test if a hitrecord belongs to a csg correctly
    csg_D = CSG(CSG(sphere1, sphere3, RayTracer.DIFFERENCE), sphere2, RayTracer.DIFFERENCE)

    @test !RayTracer._belongs(hr_z_1, csg_D.obj1)
    @test RayTracer._belongs(hr_z_2, csg_D.obj1)

    @testset "3 OBJ" begin
        # 3 spheres
        csg_U = CSG(CSG(sphere1, sphere2, RayTracer.UNION), sphere3, RayTracer.UNION)
        csg_I = CSG(
            CSG(sphere1, sphere2, RayTracer.INTERSECTION),
            sphere3,
            RayTracer.INTERSECTION,
        )
        csg_F =
            CSG(CSG(sphere1, sphere2, RayTracer.INTERSECTION), sphere3, RayTracer.FUSION)
        csg_D = CSG(
            CSG(sphere1, sphere2, RayTracer.INTERSECTION),
            sphere3,
            RayTracer.DIFFERENCE,
        )
        # test all intersections
        test_all_intersections(csg_U, ray_z, [hr_z_1, hr_z_2, hr_z_3, hr_z_4, hr_z_5, hr_z_6])
        test_all_intersections(csg_I, ray_z, [hr_z_3, hr_z_4])
        test_all_intersections(csg_F, ray_z, [hr_z_2, hr_z_6])
        test_all_intersections(csg_D, ray_z, [hr_z_2, hr_z_3])

        # test the last intersection, used in renderer
        test_intersection(csg_I, ray_z, hr_z_3)

        # 2 Spheres, 1 Plane
        # hr_plane will be hr_z_3_p
        csg_U = CSG(CSG(sphere1, sphere2, RayTracer.UNION), plane2, RayTracer.UNION)
        csg_I = CSG(
            CSG(sphere1, sphere2, RayTracer.INTERSECTION),
            plane2,
            RayTracer.INTERSECTION,
        )
        csg_D =
            CSG(CSG(sphere1, sphere2, RayTracer.INTERSECTION), plane2, RayTracer.DIFFERENCE)

        test_all_intersections(csg_U, ray_z, [hr_z_1, hr_z_2, hr_z_3_p, hr_z_4, hr_z_5])
        test_all_intersections(csg_I, ray_z, [hr_z_3_p, hr_z_4])
        test_all_intersections(csg_D, ray_z, [hr_z_2, hr_z_3_p])
    end
end

#! format: on
