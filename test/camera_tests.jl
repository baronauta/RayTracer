@testset "Camera" begin

    @testset "OrthogonalCamera" begin
        aspect_ratio = 2.0
        cam = OrthogonalCamera(aspect_ratio)
        ray1 = RayTracer.fire_ray(cam, 0.0, 0.0)
        ray2 = RayTracer.fire_ray(cam, 1.0, 0.0)
        ray3 = RayTracer.fire_ray(cam, 0.0, 1.0)
        ray4 = RayTracer.fire_ray(cam, 1.0, 1.0)
        # Verify that the rays are parallel by verifying that cross-products vanish
        @test RayTracer.squared_norm(cross(ray1.dir, ray2.dir)) ≈ 0.0
        @test RayTracer.squared_norm(cross(ray1.dir, ray3.dir)) ≈ 0.0
        @test RayTracer.squared_norm(cross(ray1.dir, ray4.dir)) ≈ 0.0
        # Verify that the ray hitting the corners have the right coordinates
        @test RayTracer.at(ray1, 1.0) ≈ Point(0.0, 2.0, -1.0)
        @test RayTracer.at(ray2, 1.0) ≈ Point(0.0, -2.0, -1.0)
        @test RayTracer.at(ray3, 1.0) ≈ Point(0.0, 2.0, 1.0)
        @test RayTracer.at(ray4, 1.0) ≈ Point(0.0, -2.0, 1.0)
        # Verify correctness of the transformation applied to Camera
        aspect_ratio = 2.0
        transformation = translation(-(VEC_Y) * 2.0) * rotation_z(90)
        cam = OrthogonalCamera(aspect_ratio, transformation)
        ray = RayTracer.fire_ray(cam, 0.5, 0.5)
        @test RayTracer.at(ray, 1.0) ≈ Point(0.0, -2.0, 0.0)
    end

    @testset "PerspectiveCamera" begin
        aspect_ratio = 2.0
        cam = PerspectiveCamera(aspect_ratio)

        ray1 = RayTracer.fire_ray(cam, 0.0, 0.0)
        ray2 = RayTracer.fire_ray(cam, 1.0, 0.0)
        ray3 = RayTracer.fire_ray(cam, 0.0, 1.0)
        ray4 = RayTracer.fire_ray(cam, 1.0, 1.0)

        # Verify that all the rays depart from the same point
        @test ray1.origin ≈ ray2.origin
        @test ray2.origin ≈ ray3.origin
        @test ray3.origin ≈ ray4.origin

        # Verify that the ray hitting the corners have the right coordinates
        @test RayTracer.at(ray1, 1.0) ≈ Point(0.0, 2.0, -1.0)
        @test RayTracer.at(ray2, 1.0) ≈ Point(0.0, -2.0, -1.0)
        @test RayTracer.at(ray3, 1.0) ≈ Point(0.0, 2.0, 1.0)
        @test RayTracer.at(ray4, 1.0) ≈ Point(0.0, -2.0, 1.0)
        # Verify correctness of the transformation applied to Camera
        aspect_ratio = 2.0
        screen_distance = 1.0
        transformation = translation(-(VEC_Y) * 2.0) * rotation_z(90)
        cam = PerspectiveCamera(screen_distance, aspect_ratio, transformation)
        ray = RayTracer.fire_ray(cam, 0.5, 0.5)
        @test RayTracer.at(ray, 1.0) ≈ Point(0.0, -2.0, 0.0)
    end

    @testset "ImageTracer" begin
        #Set up
        function setup()
            aspect_ratio = 2.0
            width = 4
            height = 2
            img = HdrImage(width, height)
            cam = PerspectiveCamera(aspect_ratio)
            tracer = ImageTracer(img, cam)
            return tracer
        end

        # Test for pixel's coordinates (u,v)
        function test1(tracer)
            ray1 = RayTracer.fire_ray(tracer, 1, 1, u_pixel = 2.5, v_pixel = 1.5)
            ray2 = RayTracer.fire_ray(tracer, 3, 2, u_pixel = 0.5, v_pixel = 0.5)
            @test ray1 ≈ ray2
        end

        # Test for image coverage
        function test2(tracer)
            function lambda(ray::Ray)
                return RGB(0.0, 0.7, 0.8)
            end
            RayTracer.fire_all_rays!(tracer, lambda; progress_flag = false)
            for row = 1:tracer.image.height
                for col = 1:tracer.image.width
                    @test RayTracer.get_pixel(tracer.image, col, row) ≈ RGB(0.0, 0.7, 0.8)
                end
            end
        end

        # Test for orientation
        function test3(tracer)
            top_left_ray = RayTracer.fire_ray(tracer, 1, 1, u_pixel = 0.0, v_pixel = 0.0)
            bottom_right_ray =
                RayTracer.fire_ray(tracer, 4, 2, u_pixel = 1.0, v_pixel = 1.0)
            @test Point(0.0, 2.0, 1.0) ≈ RayTracer.at(top_left_ray, 1.0)
            @test Point(0.0, -2.0, -1.0) ≈ RayTracer.at(bottom_right_ray, 1.0)
        end

        # Do the tests
        for test in [test1, test2, test3]
            test(setup())
        end

    end

    
    @testset "Antialiasing" begin
        samples_per_pixel = 16
        @test RayTracer.is_square(samples_per_pixel)
        sqrt_samples = round(Int, sqrt(samples_per_pixel))
        pcg = RayTracer.PCG()

        jitter_pairs = []

        for i = 1:sqrt_samples
            for j = 1:sqrt_samples
                du, dv = RayTracer.jitter_sampling(i, j, sqrt_samples, pcg)
                push!(jitter_pairs, (du, dv))

                # Compute subpixel bounds
                # Top-left is u=0, v=1
                u_min = (i - 1) / sqrt_samples
                u_max = i / sqrt_samples
                v_min = 1.0 - j / sqrt_samples
                v_max = 1.0 - (j - 1) / sqrt_samples

                @test u_min <= du <= u_max
                @test v_min <= dv <= v_max
            end
        end

        @test length(jitter_pairs) == samples_per_pixel
    end

    @testset "Camera motion" begin

        @testset "Update camera position" begin
            aspect_ratio = 1.
            start_pos = translation(Vec(1., 0., 0.))
            movement = translation(Vec(3., 2., 1.))

            # PerspetiveCamera
            screen_distance = 2.
            p_camera = PerspectiveCamera(screen_distance, aspect_ratio, start_pos)
            new_p_camera = RayTracer.update_camera(p_camera, movement)
            @test p_camera.transformation ≈ start_pos
            @test new_p_camera.transformation ≈ translation(Vec(4., 2., 1.))
            @test new_p_camera.distance == screen_distance
            @test new_p_camera.aspect_ratio == aspect_ratio

            # OrthogonalCamera
            o_camera = OrthogonalCamera(aspect_ratio, start_pos)
            new_o_camera = RayTracer.update_camera(o_camera, movement)
            @test o_camera.transformation ≈ start_pos
            @test new_o_camera.transformation ≈ translation(Vec(4., 2., 1.))
            @test new_p_camera.aspect_ratio == aspect_ratio
        end

        @testset "Animation step" begin
            initial_trans = rotation_x(30.) * translation(Vec(1.,1.,1.))
            camera = PerspectiveCamera(1., 1., initial_trans)

            translation_motion = RayTracer.Motion(Vec(10., 20., 30.), nothing, nothing, 10)
            for i in 1:translation_motion.num_frames
                new_camera = RayTracer.animation_step(camera, translation_motion, i)
                expected_transformation = translation(i*Vec(1., 2., 3.)) * initial_trans
                @test new_camera.transformation ≈ expected_transformation
            end

            rotation_motion = RayTracer.Motion(nothing, "Y", 30., 10)
            for i in 1:rotation_motion.num_frames
                new_camera = RayTracer.animation_step(camera, rotation_motion, i)
                expected_transformation = rotation_y(i*3.) * initial_trans
                @test new_camera.transformation ≈ expected_transformation
            end

        end

    end
end