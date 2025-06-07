@testset "Parser" begin
    # This test is meant to check that given a correct text file,
    # the scene is correctly built.

    stream = IOBuffer(
        """
        float clock(150)

        material sky_material(
            diffuse(uniform(<0, 0, 0>)),
            uniform(<0.7, 0.5, 1>)
        )

        # Here is a comment

        material ground_material(
            diffuse(checkered(<0.3, 0.5, 0.1>,
                              <0.1, 0.2, 0.5>, 4)),
            uniform(<0, 0, 0>)
        )

        material sphere_material(
            specular(uniform(<0.5, 0.5, 0.5>)),
            uniform(<0, 0, 0>)
        )

        plane (sky_material, translation([0, 0, 100]) * rotation_y(clock))
        plane (ground_material, identity)

        sphere(sphere_material, translation([0, 0, 1]))

        camera(perspective, rotation_z(30) * translation([-4, 0, 1]), 1.0, 2.0)
        """
    )

    instream = RayTracer.InputStream(stream, "test")
    scene = RayTracer.parse_scene(instream)

    # Check that `float clock(150)` is stored in scene.float_variables
    @test length(scene.float_variables) == 1
    @test haskey(scene.float_variables, "clock")
    @test scene.float_variables["clock"] == 150.0

    # Check materials, i.e. `sphere_material`, `sky_material`, `ground_material`
    @test length(scene.materials) == 3
    @test haskey(scene.materials, "sphere_material")
    @test haskey(scene.materials, "sky_material")
    @test haskey(scene.materials, "ground_material")

    sphere_material = scene.materials["sphere_material"]
    sky_material = scene.materials["sky_material"]
    ground_material = scene.materials["ground_material"]

    @test isa(sky_material.brdf, DiffuseBRDF)
    @test isa(sky_material.brdf.pigm, UniformPigment)
    @test sky_material.brdf.pigm.color ≈ RGB(0., 0., 0.)

    @test isa(ground_material.brdf, DiffuseBRDF)
    @test isa(ground_material.brdf.pigm, CheckeredPigment)
    @test ground_material.brdf.pigm.color1 ≈ RGB(0.3, 0.5, 0.1)
    @test ground_material.brdf.pigm.color2 ≈ RGB(0.1, 0.2, 0.5)
    @test ground_material.brdf.pigm.squares_per_unit == 4

    @test isa(sphere_material.brdf, SpecularBRDF)
    @test isa(sphere_material.brdf.pigm, UniformPigment)
    @test sphere_material.brdf.pigm.color ≈ RGB(0.5, 0.5, 0.5)

    @test isa(sky_material.emitted_radiance, UniformPigment)
    @test sky_material.emitted_radiance.color ≈ RGB(0.7, 0.5, 1.0)
    @test isa(ground_material.emitted_radiance, UniformPigment)
    @test ground_material.emitted_radiance.color ≈ RGB(0., 0., 0.)
    @test isa(sphere_material.emitted_radiance, UniformPigment)
    @test sphere_material.emitted_radiance.color ≈ RGB(0., 0., 0.)

    # Check shapes
    @test length(scene.world.shapes) == 3
    @test isa(scene.world.shapes[1], Plane)
    @test scene.world.shapes[1].transformation ≈ translation(Vec(0., 0., 100.)) * rotation_y(150.0)
    
    @test isa(scene.world.shapes[2], Plane)
    @test scene.world.shapes[2].transformation ≈ Transformation()
    @test isa(scene.world.shapes[3], Sphere)
    @test scene.world.shapes[3].transformation ≈ translation(Vec(0., 0., 1.))

    # Check camera
    @test isa(scene.camera, PerspectiveCamera)
    @test scene.camera.transformation ≈ rotation_z(30) * translation(Vec(-4., 0., 1.))
    @test scene.camera.aspect_ratio ≈ 1.0
    @test scene.camera.distance ≈ 2.0
end

@testset "Parser exceptions" begin
    
end
