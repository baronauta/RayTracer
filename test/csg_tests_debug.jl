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

#  @testset "3 Spheres - Union in Difference" begin # (DEBUGGING)
#         sphere1 = Sphere()
#         sphere2 = Sphere(translation(Vec(0.0, 0.0, 1.0)), Material())
#         sphere3 = Sphere(translation(Vec(0.0, 0.0, -0.5)), Material())

#         # csg_U = CSG(CSG(sphere1, sphere2, RayTracer.UNION), sphere3, RayTracer.UNION)
#         # csg_I = CSG(CSG(sphere1, sphere2, RayTracer.INTERSECTION), sphere3, RayTracer.INTERSECTION)
#         # csg_F = CSG(CSG(sphere1, sphere2, RayTracer.INTERSECTION), sphere3, RayTracer.FUSION)
#         csg_A = CSG(sphere1, sphere3, RayTracer.DIFFERENCE)
#         csg_D = CSG(csg_A, sphere2, RayTracer.DIFFERENCE)

#         ray_z = Ray(Point(0.0, 0.0, 3.0), -VEC_Z)

#         hr_z_1 = HitRecord(Point(0.0, 0.0, 2.0), Normal(0.0, 0.0, 1.0), Vec2D(0.0, 0.0), 1., ray_z, sphere2)
#         hr_z_2 = HitRecord(Point(0.0, 0.0, 1.0), Normal(0.0, 0.0, 1.0), Vec2D(0.0, 0.0), 2., ray_z, sphere1)
#         hr_z_3 = HitRecord(Point(0.0, 0.0, 0.5), Normal(0.0, 0.0, 1.0), Vec2D(0.0, 0.0), 2.5, ray_z, sphere3)
#         hr_z_4 = HitRecord(Point(0.0, 0.0, 0.0), Normal(0.0, 0.0, 1.0), Vec2D(0.0, 1.0), 3., ray_z, sphere2)
#         hr_z_5 = HitRecord(Point(0.0, 0.0, -1.0), Normal(0.0, 0.0, 1.0), Vec2D(0.0, 1.0), 4., ray_z, sphere1)
#         hr_z_6 = HitRecord(Point(0.0, 0.0, -1.5), Normal(0.0, 0.0, 1.0), Vec2D(0.0, 1.0), 4.5, ray_z, sphere3)

#         # hits_U = [hr_z_1, hr_z_2, hr_z_3, hr_z_4, hr_z_5, hr_z_6]
#         # hits_I = [hr_z_3, hr_z_4]
#         # hits_F = [hr_z_2, hr_z_6]
#         hits_D = [nothing]

#         # for (csg, exp_hits) in zip([csg_U, csg_I, csg_F, csg_D], [hits_U, hits_I, hits_F, hits_D])
#     println(typeof(csg_D.obj1))
#         if csg_D.obj1 isa CSG
#             is_obj1 = ((hr_z_2.shape ≈ csg_D.obj1.obj1) || (hr_z_2.shape ≈ csg_D.obj1.obj2))
#         else
#             is_obj1 = (hr_z_2.shape ≈ csg_D.obj1)
#         end
#         println(is_obj1,"\n")

#         # for (csg, exp_hits) in zip([csg_D], [hits_D])
#         #     hits = RayTracer.ray_intersection(csg, ray_z; all = true)
#         #     #println(length(hits))
#         #     #@test length(exp_hits) == length(hits)
#         #     for (exp_hit, hit) in zip(exp_hits, hits)
#         #         #println("\n", hit)
#         #         #@test hit ≈ exp_hit  

#         #         #=
#         #         =#

#         #     end
#         # end
#     end