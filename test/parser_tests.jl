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

        material cube_material(
            diffuse(uniform(<0.5, 0.5, 0.5>)),
            uniform(<0, 0, 0>)
        )

        plane plane_1_name(sky_material, translation([0, 0, 100]) * rotation_y(clock))
        plane plane_2_name(ground_material, identity)

        copy new_plane(plane_2_name)

        sphere  sphere_1_name(sphere_material, translation([0, 0, 1]))

        cube cube_1_name(cube_material, scaling(1.,2.,3.))

        csg csg_1_name(sphere_1_name, plane_2_name, difference, identity)

        csg csg_2_name(csg_1_name, cube_1_name, union, rotation_y(clock))

        camera(perspective, rotation_z(30) * translation([-4, 0, 1]), 2.0)

        motion(translation([10, 20, 30]), 10)
        """
    )

    aspect_ratio = 1.
    instream = RayTracer.InputStream(stream, "test")
    scene = RayTracer.parse_scene(instream, aspect_ratio)

    # Check that aspect_ratio is correctly stored in scene.float_variables
    @test haskey(scene.float_variables, "_aspect_ratio")
    @test scene.float_variables["_aspect_ratio"] == aspect_ratio

    # Check that `float clock(150)` is stored in scene.float_variables
    @test length(scene.float_variables) == 2   # _aspect_ratio and clock
    @test haskey(scene.float_variables, "clock")
    @test scene.float_variables["clock"] == 150.0

    # Check materials, i.e. `sphere_material`, `sky_material`, `ground_material`, `cube_material`
    @test length(scene.materials) == 4
    @test haskey(scene.materials, "sphere_material")
    @test haskey(scene.materials, "sky_material")
    @test haskey(scene.materials, "ground_material")
    @test haskey(scene.materials, "cube_material")

    sphere_material = scene.materials["sphere_material"]
    sky_material = scene.materials["sky_material"]
    ground_material = scene.materials["ground_material"]
    cube_material = scene.materials["cube_material"]

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
    
    @test isa(cube_material.brdf, DiffuseBRDF)
    @test isa(cube_material.brdf.pigm, UniformPigment)
    @test cube_material.brdf.pigm.color ≈ RGB(0.5, 0.5, 0.5)

    @test isa(sky_material.emitted_radiance, UniformPigment)
    @test sky_material.emitted_radiance.color ≈ RGB(0.7, 0.5, 1.0)
    @test isa(ground_material.emitted_radiance, UniformPigment)
    @test ground_material.emitted_radiance.color ≈ RGB(0., 0., 0.)
    @test isa(sphere_material.emitted_radiance, UniformPigment)
    @test sphere_material.emitted_radiance.color ≈ RGB(0., 0., 0.)
    @test isa(cube_material.emitted_radiance, UniformPigment)
    @test cube_material.emitted_radiance.color ≈ RGB(0., 0., 0.)

    # Check shapes
    sky_material = Material(DiffuseBRDF(UniformPigment(RGB(0.0, 0.0, 0.0))), UniformPigment(RGB(0.7, 0.5, 1.0)))
    ground_material = Material(DiffuseBRDF(CheckeredPigment(RGB(0.3, 0.5, 0.1), RGB(0.1, 0.2, 0.5), 4)), UniformPigment(RGB(0.0, 0.0, 0.0)))
    sphere_material = Material(SpecularBRDF(UniformPigment(RGB(0.5, 0.5, 0.5))), UniformPigment(RGB(0.0, 0.0, 0.0)))
    cube_material = Material(DiffuseBRDF(UniformPigment(RGB(0.5, 0.5, 0.5))), UniformPigment(RGB(0.0, 0.0, 0.0)))
    # test for shapes list
    @test length(scene.shapes) == 7
    @test haskey(scene.shapes, "plane_1_name")
    @test haskey(scene.shapes, "plane_2_name")
    @test haskey(scene.shapes, "sphere_1_name")
    @test haskey(scene.shapes, "cube_1_name")
    @test haskey(scene.shapes, "csg_1_name")
    @test haskey(scene.shapes, "csg_2_name")
    @test haskey(scene.shapes, "new_plane")

    plane_1 = Plane(translation(Vec(0.0, 0.0, 100.0)) * rotation_y(150), sky_material)
    @test scene.shapes["plane_1_name"] ≈ plane_1

    transf_csg_2 = rotation_y(150)
    # plane_2 and sphere_1 are used in csg_1, that is used in csg_2.
    # need to compose the csg_1 transformation, but is identity, with csg_2 transformation.
    plane_2 = Plane(ground_material)
    sphere_1 = Sphere(translation(Vec(0.0, 0.0, 1.0)), sphere_material)
    plane_2_t = Plane(transf_csg_2,ground_material)
    sphere_1_t = Sphere(transf_csg_2 * translation(Vec(0.0, 0.0, 1.0)), sphere_material)
    @test scene.shapes["plane_2_name"] ≈ plane_2_t
    @test scene.shapes["sphere_1_name"] ≈ sphere_1_t

    # cube_1 is used in csg_2.
    # need to compose the csg_2 transformation for the cube.
    cube_1 = Cube(scaling(1.0, 2.0, 3.0), cube_material)
    cube_1_t = Cube(transf_csg_2 * scaling(1.0, 2.0, 3.0), cube_material)
    @test scene.shapes["cube_1_name"] ≈ cube_1_t

    # csg_1 is used in csg_2.
    # need to compose the csg_2 transformation for the csg.
    csg_1 = Csg(sphere_1, plane_2, RayTracer.DIFFERENCE, Transformation())
    csg_1_t = Csg(deepcopy(sphere_1), deepcopy(plane_2), RayTracer.DIFFERENCE, transf_csg_2 * Transformation())
    @test scene.shapes["csg_1_name"] ≈ csg_1_t

    csg_2 = Csg(csg_1, cube_1, RayTracer.UNION, transf_csg_2)
    @test scene.shapes["csg_2_name"] ≈ csg_2
    
    #test for world shapes list
    @test length(scene.world.shapes) == 3
    @test scene.world.shapes[1] ≈ csg_2
    @test scene.world.shapes[2] ≈ plane_1
    @test scene.world.shapes[3] ≈ Plane() # test for copy

    # Check camera
    @test isa(scene.camera, PerspectiveCamera)
    @test scene.camera.transformation ≈ rotation_z(30) * translation(Vec(-4., 0., 1.))
    @test scene.camera.aspect_ratio ≈ aspect_ratio    # Parsed from scene.float_variables["_aspect_ratio"]
    @test scene.camera.distance ≈ 2.0

    # Check motion
    @test scene.motion.vec ≈ Vec(10., 20., 30.)
    @test scene.motion.num_frames == 10
end

@testset "Parser exceptions" begin

    @testset "Unknown material" begin
        stream = IOBuffer("""
            plane(sky_material, rotation_y(10))
        """)

        instream = RayTracer.InputStream(stream, "test")

        err_thrown = false
        try
            _ = RayTracer.parse_scene(instream, 1.0)
        catch e
            if isa(e, GrammarError)
                err_thrown = true
            else
                rethrow(e)  # Re-throw unexpected exceptions
            end
        end
        @test err_thrown
    end


    @testset "Unknown float" begin
        stream = IOBuffer(
            """
            float clock(13)

            material sky_material(
                diffuse(uniform(<0, 0, 0>)),
                uniform(<0.7, 0.5, 1>)
            )

            plane(sky_material, rotation_y(pippo))
            """
        )

        instream = RayTracer.InputStream(stream, "test")

        err_thrown = false
        try
            _ = RayTracer.parse_scene(instream, 1.0)
        catch e
            if isa(e, GrammarError)
                err_thrown = true
            else
                rethrow(e)  # Re-throw unexpected exceptions
            end
        end
        @test err_thrown
    end

    @testset "Double camera" begin
        stream = IOBuffer(
            """
            camera(perspective, rotation_z(30) * translation([-4, 0, 1]), 1.0)
            camera(orthogonal, identity, 1.0)
            """
        )

        instream = RayTracer.InputStream(stream, "test")

        err_thrown = false
        try
            _ = RayTracer.parse_scene(instream, 1.0)
        catch e
            if isa(e, GrammarError)
                err_thrown = true
            else
                rethrow(e)  # Re-throw unexpected exceptions
            end
        end
        @test err_thrown
    end

    @testset "Missing keyword" begin

        stream = IOBuffer(
            """
            camera(rullo, rotation_z(30) * translation([-4, 0, 1]), 1.0)
            """
        )

        instream = RayTracer.InputStream(stream, "test")

        err_thrown = false
        try
            _ = RayTracer.parse_scene(instream, 1.0)
        catch e
            if isa(e, GrammarError)
                err_thrown = true
            else
                rethrow(e)  # Re-throw unexpected exceptions
            end
        end
        @test err_thrown
    end

    @testset "Unexpected keyword" begin

        stream = IOBuffer(
            """
            camera(identity, rotation_z(30) * translation([-4, 0, 1]), 1.0)
            """
        )

        instream = RayTracer.InputStream(stream, "test")

        err_thrown = false
        try
            _ = RayTracer.parse_scene(instream, 1.0)
        catch e
            if isa(e, GrammarError)
                err_thrown = true
            else
                rethrow(e)  # Re-throw unexpected exceptions
            end
        end
        @test err_thrown
    end

    @testset "Wrong motion description" begin
        
        @testset "Unaccepted transformation composition" begin
            stream = IOBuffer(
                """
                motion(translation([2, 4, 5]) * scaling_x(10), 10)
                """
            )

            instream = RayTracer.InputStream(stream, "test")

            err_thrown = false
            try
                _ = RayTracer.parse_scene(instream, 1.0)
            catch e
                if isa(e, GrammarError)
                    err_thrown = true
                else
                    rethrow(e)  # Re-throw unexpected exceptions
                end
            end
            @test err_thrown
        end

        @testset "Number of frames not integer" begin
            
            stream = IOBuffer(
                """
                motion(translation([2, 4, 5]), 10.2)
                """
            )

            instream = RayTracer.InputStream(stream, "test")

            err_thrown = false
            try
                _ = RayTracer.parse_scene(instream, 1.0)
            catch e
                if isa(e, GrammarError)
                    err_thrown = true
                else
                    rethrow(e)  # Re-throw unexpected exceptions
                end
            end
            @test err_thrown
        end
    end
end
