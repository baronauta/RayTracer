@testset "Renderer" begin

    @testset "On/Off Tracer" begin
        # Create a small sphere, scale it down and translate it so that its projection
        # fits exactly into a single centered pixel in the image
        trasforme_to_little = translation(Vec(2.0, 0.0, 0.0)) * scaling(0.2, 0.2, 0.2)
        sphere = Sphere(trasforme_to_little, Material())
        img = HdrImage(3, 3)
        cam = OrthogonalCamera(1.0)
        tracer = ImageTracer(img, cam)
        world = World([sphere])
        f = ray -> onoff_tracer(world, ray)
        RayTracer.fire_all_rays!(tracer, f)

        @test RayTracer.get_pixel(img, 1, 1) ≈ BLACK
        @test RayTracer.get_pixel(img, 2, 1) ≈ BLACK
        @test RayTracer.get_pixel(img, 3, 1) ≈ BLACK

        @test RayTracer.get_pixel(img, 1, 2) ≈ BLACK
        @test RayTracer.get_pixel(img, 2, 2) ≈ WHITE
        @test RayTracer.get_pixel(img, 3, 2) ≈ BLACK

        @test RayTracer.get_pixel(img, 1, 3) ≈ BLACK
        @test RayTracer.get_pixel(img, 2, 3) ≈ BLACK
        @test RayTracer.get_pixel(img, 3, 3) ≈ BLACK
    end

    @testset "Flat Tracer" begin
        # Create a small sphere, scale it down and translate it so that its projection
        # fits exactly into a single centered pixel in the image
        trasforme_to_little = translation(Vec(2.0, 0.0, 0.0)) * scaling(0.2, 0.2, 0.2)
        sphere_color = RGB(1.0, 2.0, 3.0)
        brdf = DiffuseBRDF(UniformPigment(sphere_color))
        sphere = Sphere(trasforme_to_little, Material(brdf))
        img = HdrImage(3, 3)
        cam = OrthogonalCamera(1.0)
        tracer = ImageTracer(img, cam)
        world = World([sphere])
        f = ray -> flat_tracer(world, ray)
        RayTracer.fire_all_rays!(tracer, f)

        @test RayTracer.get_pixel(img, 1, 1) ≈ BLACK
        @test RayTracer.get_pixel(img, 2, 1) ≈ BLACK
        @test RayTracer.get_pixel(img, 3, 1) ≈ BLACK

        @test RayTracer.get_pixel(img, 1, 2) ≈ BLACK
        @test RayTracer.get_pixel(img, 2, 2) ≈ sphere_color
        @test RayTracer.get_pixel(img, 3, 2) ≈ BLACK

        @test RayTracer.get_pixel(img, 1, 3) ≈ BLACK
        @test RayTracer.get_pixel(img, 2, 3) ≈ BLACK
        @test RayTracer.get_pixel(img, 3, 3) ≈ BLACK
    end

    @testset "Furnace test" begin
        pcg = RayTracer.PCG()
        for i = 1:10
            emitted_radiance = RayTracer.random_float!(pcg)
            reflectance = RayTracer.random_float!(pcg) * 0.9

            world = World()
            # Material of diffuse BRDF with constant luminosity
            # and radiance.
            material = Material(
                DiffuseBRDF(UniformPigment(WHITE * reflectance)),
                UniformPigment(WHITE * emitted_radiance),
            )
            sphere = Sphere(material)
            add!(world, sphere)
            ray = Ray(Point(0.0, 0.0, 0.0), Vec(1.0, 0.0, 0.0))

            # Disable Russian roulette choosing russian_roulette_limit > max_depth
            color = path_tracer(
                world,
                ray,
                pcg;
                n_rays = 1,
                max_depth = 100,
                russian_roulette_limit = 101,
            )

            val = emitted_radiance / (1.0 - reflectance)
            @test color ≈ WHITE * val
        end
    end
end


