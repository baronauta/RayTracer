@testset "Furnace test" begin
    pcg = RayTracer.PCG()
    for i in 1:10
        emitted_radiance = RayTracer.random_float!(pcg)
        reflectance = RayTracer.random_float!(pcg) * 0.9

        world = World()
        # Material of diffuse BRDF with constant luminosity
        # and radiance.
        material = Material(
            DiffuseBRDF(UniformPigment(WHITE * reflectance), 0.),
            UniformPigment(WHITE * emitted_radiance)
        )
        sphere = Sphere(material)
        add!(world, sphere)
        ray = Ray(Point(0., 0., 0.), Vec(1., 0., 0.))

        # Disable Russian roulette choosing russian_roulette_limit > max_depth
        color = path_tracer(world, ray, pcg; n_rays = 1, max_depth = 100, russian_roulette_limit = 101)

        val = emitted_radiance / (1.0 - reflectance)
        @test color ≈ WHITE * val
    end
end