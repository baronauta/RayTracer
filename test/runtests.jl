using Test
include("helper.jl")

@testset "Colors" begin
    c1 = RGB(0.1, 0.2, 0.3)
    c2 = RGB(0.4, 0.5, 0.6)
    c3 = RGB(0.0, 0.7, 0.8)
    @test c1 ≈ RGB(0.1, 0.2, 0.3)
    @test c3 ≈ RGB(0.0001, 0.7001, 0.8)
    @test !(c1 ≈ c2)
    @test !(c3 ≈ RGB(0.001, 0.7001, 0.8))
    @test c1 + c2 ≈ RGB(0.5, 0.7, 0.9)
    @test 2 * c1 ≈ RGB(0.2, 0.4, 0.6)
    @test c1 * c2 ≈ RGB(0.04, 0.1, 0.18)
end

@testset "HdrImage" begin
    width = 9
    height = 6
    img = HdrImage(width, height)
    @test img.height == height
    @test img.width == width
    x = 7
    y = 5
    c = RGB(0.1, 0.2, 0.3)
    set_pixel!(img, x, y, c)
    @test img.pixels[y, x] ≈ c
    @test c ≈ get_pixel(img, x, y)
end

@testset "I/O-Read" begin
    # Unit tests
    width = 128
    height = 256
    s1 = "$width $height"
    @test (width, height) == _parse_img_size(s1)
    be = "+1.0"
    le = "-1.0"
    @test _parse_endianness(be) == 1.0
    @test _parse_endianness(le) == -1.0
    # Integration test
    for filename in ["reference_be.pfm", "reference_le.pfm"]
        file_data = read(filename)
        stream = IOBuffer(file_data)
        img = read_pfm_image(stream)
        @test get_pixel(img, 1, 1) ≈ (RGB(1.0e1, 2.0e1, 3.0e1))
        @test get_pixel(img, 2, 1) ≈ (RGB(4.0e1, 5.0e1, 6.0e1))
        @test get_pixel(img, 3, 1) ≈ (RGB(7.0e1, 8.0e1, 9.0e1))
        @test get_pixel(img, 1, 2) ≈ (RGB(1.0e2, 2.0e2, 3.0e2))
        @test get_pixel(img, 2, 2) ≈ (RGB(4.0e2, 5.0e2, 6.0e2))
        @test get_pixel(img, 3, 2) ≈ (RGB(7.0e2, 8.0e2, 9.0e2))
    end
end

@testset "I/O-Write" begin
    #! format: off
    # This is the content of "reference_le.pfm" (little-endian file)
    LE_REFERENCE_BYTES = UInt8[
    0x50, 0x46, 0x0a, 0x33, 0x20, 0x32, 0x0a, 0x2d, 0x31, 0x2e, 0x30, 0x0a,
    0x00, 0x00, 0xc8, 0x42, 0x00, 0x00, 0x48, 0x43, 0x00, 0x00, 0x96, 0x43,
    0x00, 0x00, 0xc8, 0x43, 0x00, 0x00, 0xfa, 0x43, 0x00, 0x00, 0x16, 0x44,
    0x00, 0x00, 0x2f, 0x44, 0x00, 0x00, 0x48, 0x44, 0x00, 0x00, 0x61, 0x44,
    0x00, 0x00, 0x20, 0x41, 0x00, 0x00, 0xa0, 0x41, 0x00, 0x00, 0xf0, 0x41,
    0x00, 0x00, 0x20, 0x42, 0x00, 0x00, 0x48, 0x42, 0x00, 0x00, 0x70, 0x42,
    0x00, 0x00, 0x8c, 0x42, 0x00, 0x00, 0xa0, 0x42, 0x00, 0x00, 0xb4, 0x42
    ]
    # This is the content of "reference_be.pfm" (big-endian file)
    BE_REFERENCE_BYTES = UInt8[
    0x50, 0x46, 0x0a, 0x33, 0x20, 0x32, 0x0a, 0x31, 0x2e, 0x30, 0x0a, 0x42,
    0xc8, 0x00, 0x00, 0x43, 0x48, 0x00, 0x00, 0x43, 0x96, 0x00, 0x00, 0x43,
    0xc8, 0x00, 0x00, 0x43, 0xfa, 0x00, 0x00, 0x44, 0x16, 0x00, 0x00, 0x44,
    0x2f, 0x00, 0x00, 0x44, 0x48, 0x00, 0x00, 0x44, 0x61, 0x00, 0x00, 0x41,
    0x20, 0x00, 0x00, 0x41, 0xa0, 0x00, 0x00, 0x41, 0xf0, 0x00, 0x00, 0x42,
    0x20, 0x00, 0x00, 0x42, 0x48, 0x00, 0x00, 0x42, 0x70, 0x00, 0x00, 0x42,
    0x8c, 0x00, 0x00, 0x42, 0xa0, 0x00, 0x00, 0x42, 0xb4, 0x00, 0x00
    ]
    #! format: on
    img = read_pfm_image(open("reference_le.pfm", "r"))
    buf = IOBuffer()
    write(buf, img)
    contents = take!(buf)
    if little_endian
        @test contents == LE_REFERENCE_BYTES
    else
        @test contents == BE_REFERENCE_BYTES
    end
    write(buf, img, endianness = 1.0)
    contents = take!(buf)
    @test contents == BE_REFERENCE_BYTES
end

@testset "ToneMapping" begin
    # Luminosity
    col1 = RGB(10.0, 3.0, 2.0)
    @test luminosity(col1, mean_type = :max_min) ≈ 6
    @test luminosity(col1, mean_type = :arithmetic) ≈ 5
    @test luminosity(col1, mean_type = :weighted) ≈ 5
    @test luminosity(col1, mean_type = :weighted, weights = [1, 2, 5]) ≈ 3.25
    @test isapprox(luminosity(col1, mean_type = :distance), 10.6301; atol = 0.0001)
    # Logarithmic average
    # Image for test
    img = HdrImage(2, 1)
    set_pixel!(img, 1, 1, RGB(5.0, 10.0, 15.0)) # Luminosity (min-max): 10.0
    set_pixel!(img, 2, 1, RGB(500.0, 1000.0, 1500.0)) # Luminosity (min-max): 1000.0
    @test log_average(img, mean_type = :max_min, delta = 0.0) ≈ 100.0
    # Test that delta helps in avoiding log singularity when a pixel is black
    img = HdrImage(2, 1)
    set_pixel!(img, 1, 1, RGB(50.0, 100.0, 150.0)) # Luminosity (min-max): 100.0
    @test log_average(img, mean_type = :max_min) ≈ 1e-4
    # Normalization
    # Image for test
    img = HdrImage(2, 1)
    set_pixel!(img, 1, 1, RGB(5.0, 10.0, 15.0))
    set_pixel!(img, 2, 1, RGB(500.0, 1000.0, 1500.0))
    normalize_image!(img, factor = 1000.0, lumi = 100.0)
    @test get_pixel(img, 1, 1) ≈ RGB(0.5e2, 1.0e2, 1.5e2)
    @test get_pixel(img, 2, 1) ≈ RGB(0.5e4, 1.0e4, 1.5e4)
    normalize_image!(img, factor = 1000.0)
    @test get_pixel(img, 1, 1) ≈ RGB(0.5e2, 1.0e2, 1.5e2)
    @test get_pixel(img, 2, 1) ≈ RGB(0.5e4, 1.0e4, 1.5e4)
    # Clamp image
    # Image for test
    img = HdrImage(2, 1)
    set_pixel!(img, 1, 1, RGB(5.0, 10.0, 15.0))
    set_pixel!(img, 2, 1, RGB(500.0, 1000.0, 1500.0))
    # Just check that the R/G/B values are within the expected boundaries
    clamp_image!(img)
    for pixel in img.pixels
        @test 0 <= pixel.r <= 1
        @test 0 <= pixel.g <= 1
        @test 0 <= pixel.b <= 1
    end
    # Write LDR image ?
end

@testset "Geometry" begin

    @testset "Point" begin
        p = Point(1.0, 2.0, 3.0)
        q = Point(4.0, 5.0, 6.0)
        @test p ≈ p
        @test !(p ≈ q)
        # Difference between Point
        @test (q - p) ≈ Vec(3.0, 3.0, 3.0)
        # Sum/Difference between a Point and a Vec
        v = Vec(7.0, 8.0, 9.0)
        @test (p + v) ≈ Point(8.0, 10.0, 12.0)
        @test (p - v) ≈ Point(-6.0, -6.0, -6.0)
        # Conversion of a Point into a Vec
        @test point_to_vec(p) ≈ Vec(1.0, 2.0, 3.0)
    end

    @testset "Vectors" begin
        v = Vec(1.0, 2.0, 3.0)
        u = Vec(4.0, 5.0, 6.0)
        @test v ≈ v
        @test !(v ≈ u)
        # Vec sum
        @test (v + u) ≈ Vec(5.0, 7.0, 9.0)
        @test (u - v) ≈ Vec(3.0, 3.0, 3.0)
        # Vec * scalar
        @test (v * 2) ≈ Vec(2.0, 4.0, 6.0)
        @test (2 * v) ≈ Vec(2.0, 4.0, 6.0)
        @test neg(v) ≈ Vec(-1.0, -2.0, -3.0)
        # Vec dot product, cross product and norm
        @test dot(v, u) ≈ 32.0
        @test cross(v, u) ≈ Vec(-3.0, 6.0, -3.0)
        @test squared_norm(v) ≈ 14.0
        @test norm(v)^2 ≈ 14.0
        # Conversion Vec to Normal
        @test vec_to_normal(v) ≈ Normal(1.0, 2.0, 3.0)
    end

    @testset "Normal" begin
        n = Normal(0.1, 0.2, 0.3)
        m = Normal(0.4, 0.5, 0.6)
        @test n ≈ n
        @test !(n ≈ m)
        # Normal * scalar
        @test (m * 0.5) ≈ Normal(0.2, 0.25, 0.3)
        @test (0.5 * m) ≈ Normal(0.2, 0.25, 0.3)
        # Normal dot product, cross product
        @test dot(n, m) ≈ 0.32
        @test cross(n, m) ≈ Normal(-0.03, 0.06, -0.03)
        v = Vec(0.4, 0.5, 0.6)
        @test cross(n, v) ≈ Vec(-0.03, 0.06, -0.03)
    end
end
#! format: off
@testset "Transformation" begin

    @testset "Consistency" begin
        m = Matrix{Float32}([
            1.0 2.0 3.0 4.0
            5.0 6.0 7.0 8.0
            9.0 9.0 8.0 7.0
            6.0 5.0 4.0 1.0
        ])
        invm = Matrix{Float32}(
            [
                 -3.75   2.75 -1.0  0.0
                 4.375 -3.875  2.0 -0.5
                   0.5    0.5 -1.0  1.0
                -1.375  0.875  0.0 -0.5
            ],
        )
        T = Transformation(HomMatrix(m), HomMatrix(invm))
        @test _is_consistent(T)
        # Create a copy of the matrices so that each Transformation has its own copy of the data
        T1 = Transformation(HomMatrix(copy(m)), HomMatrix(copy(invm)))
        T2 = Transformation(HomMatrix(copy(m)), HomMatrix(copy(invm)))
        T3 = Transformation(HomMatrix(copy(m)), HomMatrix(copy(invm)))
        @test T ≈ T1
        # Change one element of T.M: this makes T not consistent
        T2.M.matrix[1, 1] += 1
        @test !(T ≈ T2)
        @test !(_is_consistent(T2))
        # Change one element of T.invM: this makes T not consistent
        T3.invM.matrix[1, 3] += 1
        @test !(T ≈ T3)
        @test !(_is_consistent(T3))
    end

    @testset "Multiplication" begin
        m1 = Matrix{Float32}([
            1.0 2.0 3.0 4.0
            5.0 6.0 7.0 8.0
            9.0 9.0 8.0 7.0
            6.0 5.0 4.0 1.0
        ])
        invm1 = Matrix{Float32}(
            [
                 -3.75   2.75 -1.0  0.0
                 4.375 -3.875  2.0 -0.5
                   0.5    0.5 -1.0  1.0
                -1.375  0.875  0.0 -0.5
            ],
        )
        T1 = Transformation(HomMatrix(m1), HomMatrix(invm1))
        @test _is_consistent(T1)

        m2 = Matrix{Float32}([
            3.0 5.0 2.0 4.0
            4.0 1.0 0.0 5.0
            6.0 3.0 2.0 0.0
            1.0 4.0 2.0 1.0
        ])
        invm2 = Matrix{Float32}(
            [
                  0.4 -0.2  0.2 -0.6
                  2.9 -1.7  0.2 -3.1
                -5.55 3.15 -0.4 6.45
                 -0.9  0.7 -0.2  1.1
            ],
        )
        T2 = Transformation(HomMatrix(m2), HomMatrix(invm2))
        @test _is_consistent(T2)

        expected_m = Matrix{Float32}(
            [
                 33.0  32.0 16.0 18.0
                 89.0  84.0 40.0 58.0
                118.0 106.0 48.0 88.0
                 63.0  51.0 22.0 50.0
            ],
        )
        expected_invm = Matrix{Float32}(
            [
                 -1.45    1.45  -1.0  0.6
                -13.95   11.95  -6.5  2.6
                25.525 -22.025 12.25 -5.2
                 4.825  -4.325   2.5 -1.1
            ],
        )
        expected = Transformation(HomMatrix(expected_m), HomMatrix(expected_invm))
        @test _is_consistent(expected)

        prod = T1 * T2
        @test expected ≈ prod
    end

    @testset "× Vec/Point/Normal" begin
        m_mat = Matrix{Float32}([
            1.0 2.0 3.0 4.0
            5.0 6.0 7.0 8.0
            9.0 9.0 8.0 7.0
            0.0 0.0 0.0 1.0
        ])
        invm_mat = Matrix{Float32}(
            [
                -3.75  2.75 -1.0  0.0
                 5.75 -4.75  2.0  1.0
                -2.25  2.25 -1.0 -2.0
                  0.0   0.0  0.0  1.0
            ],
        )
        T = Transformation(HomMatrix(m_mat), HomMatrix(invm_mat))
        @test _is_consistent(T)

        expected_v = Vec(14.0, 38.0, 51.0)
        mul_vec = T * Vec(1.0, 2.0, 3.0)
        @test mul_vec ≈ expected_v
        expected_p = Point(18.0, 46.0, 58.0)
        mul_point = T * Point(1.0, 2.0, 3.0)
        @test mul_point ≈ expected_p
        expected_n = Normal(-8.75, 7.75, -3.0)
        mul_normal = T * Normal(3.0, 2.0, 4.0)
        @test mul_normal ≈ expected_n
    end

    @testset "Translation" begin
        tr1 = translation(Vec(1.0, 2.0, 3.0))
        @test _is_consistent(tr1)
        tr2 = translation(Vec(4.0, 6.0, 8.0))
        @test _is_consistent(tr2)
        prod = tr1 * tr2
        @test _is_consistent(prod)
        expected = translation(Vec(5.0, 8.0, 11.0))
        @test prod ≈ expected
    end

    @testset "Rotations" begin
        @test _is_consistent(rotation_x(0.1))
        @test _is_consistent(rotation_y(0.1))
        @test _is_consistent(rotation_z(0.1))
        @test (rotation_x(90) * VEC_Y) ≈ VEC_Z
        @test (rotation_y(90) * VEC_Z) ≈ VEC_X
        @test (rotation_z(90) * VEC_X) ≈ VEC_Y
    end

    @testset "Scaling" begin
        tr1 = scaling(2.0, 5.0, 10.0)
        @test _is_consistent(tr1)
        tr2 = scaling(3.0, 2.0, 4.0)
        @test _is_consistent(tr2)
        prod = tr1 * tr2
        @test _is_consistent(prod)
        expected = scaling(6.0, 10.0, 40.0)
        @test prod ≈ expected
    end
end
#! format: on

@testset "Ray" begin
    # ≈
    ray1 = Ray(Point(1.0, 2.0, 3.0), Vec(5.0, 4.0, -1.0))
    ray2 = Ray(Point(1.0, 2.0, 3.0), Vec(5.0, 4.0, -1.0))
    ray3 = Ray(Point(1.0, 2.0, 3.0), Vec(3.0, 9.0, 4.0))
    ray4 = Ray(Point(5.0, 1.0, 4.0), Vec(5.0, 4.0, -1.0))
    @test ray1 ≈ ray2
    @test !(ray1 ≈ ray3)
    @test !(ray1 ≈ ray4)
    # at method
    ray = Ray(Point(1.0, 2.0, 4.0), Vec(4.0, 2.0, 1.0))
    at(ray, 0.0) ≈ ray.origin
    at(ray, 1.0) ≈ Point(5.0, 4.0, 5.0)
    at(ray, 2.0) ≈ Point(9.0, 6.0, 6.0)
    # Ray transformation
    ray = Ray(Point(1.0, 2.0, 3.0), Vec(6.0, 5.0, 4.0))
    transformation = translation(Vec(10.0, 11.0, 12.0)) * rotation_x(90.0)
    newray = transform(ray, transformation)
    @test newray.origin ≈ Point(11.0, 8.0, 14.0)
    @test newray.dir ≈ Vec(6.0, -4.0, 5.0)
end

@testset "Camera" begin

    @testset "OrthogonalCamera" begin
        aspect_ratio = 2.0
        cam = OrthogonalCamera(aspect_ratio)
        ray1 = fire_ray(cam, 0.0, 0.0)
        ray2 = fire_ray(cam, 1.0, 0.0)
        ray3 = fire_ray(cam, 0.0, 1.0)
        ray4 = fire_ray(cam, 1.0, 1.0)
        # Verify that the rays are parallel by verifying that cross-products vanish
        @test squared_norm(cross(ray1.dir, ray2.dir)) ≈ 0.0
        @test squared_norm(cross(ray1.dir, ray3.dir)) ≈ 0.0
        @test squared_norm(cross(ray1.dir, ray4.dir)) ≈ 0.0
        # Verify that the ray hitting the corners have the right coordinates
        @test at(ray1, 1.0) ≈ Point(0.0, 2.0, -1.0)
        @test at(ray2, 1.0) ≈ Point(0.0, -2.0, -1.0)
        @test at(ray3, 1.0) ≈ Point(0.0, 2.0, 1.0)
        @test at(ray4, 1.0) ≈ Point(0.0, -2.0, 1.0)
        # Verify correctness of the transformation applied to Camera
        aspect_ratio = 2.0
        transformation = translation(neg(VEC_Y) * 2.0) * rotation_z(90)
        cam = OrthogonalCamera(aspect_ratio, transformation)
        ray = fire_ray(cam, 0.5, 0.5)
        @test at(ray, 1.0) ≈ Point(0.0, -2.0, 0.0)
    end

    @testset "PerspectiveCamera" begin
        aspect_ratio = 2.0
        cam = PerspectiveCamera(aspect_ratio)

        ray1 = fire_ray(cam, 0.0, 0.0)
        ray2 = fire_ray(cam, 1.0, 0.0)
        ray3 = fire_ray(cam, 0.0, 1.0)
        ray4 = fire_ray(cam, 1.0, 1.0)

        # Verify that all the rays depart from the same point
        @test ray1.origin ≈ ray2.origin
        @test ray2.origin ≈ ray3.origin
        @test ray3.origin ≈ ray4.origin

        # Verify that the ray hitting the corners have the right coordinates
        @test at(ray1, 1.0) ≈ Point(0.0, 2.0, -1.0)
        @test at(ray2, 1.0) ≈ Point(0.0, -2.0, -1.0)
        @test at(ray3, 1.0) ≈ Point(0.0, 2.0, 1.0)
        @test at(ray4, 1.0) ≈ Point(0.0, -2.0, 1.0)
        # Verify correctness of the transformation applied to Camera
        aspect_ratio = 2.0
        screen_distance = 1.0
        transformation = translation(neg(VEC_Y) * 2.0) * rotation_z(90)
        cam = PerspectiveCamera(screen_distance, aspect_ratio, transformation)
        ray = fire_ray(cam, 0.5, 0.5)
        @test at(ray, 1.0) ≈ Point(0.0, -2.0, 0.0)
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
            ray1 = fire_ray(tracer, 1, 1, u_pixel = 2.5, v_pixel = 1.5)
            ray2 = fire_ray(tracer, 3, 2, u_pixel = 0.5, v_pixel = 0.5)
            @test ray1 ≈ ray2
        end

        # Test for image coverage
        function test2(tracer)
            function lambda(ray::Ray)
                return RGB(0.0, 0.7, 0.8)
            end
            fire_all_rays!(tracer, lambda)
            for row = 1:tracer.image.height
                for col = 1:tracer.image.width
                    @test get_pixel(tracer.image, col, row) ≈ RGB(0.0, 0.7, 0.8)
                end
            end
        end

        # Test for orientation
        function test3(tracer)
            top_left_ray = fire_ray(tracer, 1, 1, u_pixel = 0.0, v_pixel = 0.0)
            bottom_right_ray = fire_ray(tracer, 4, 2, u_pixel = 1.0, v_pixel = 1.0)
            @test Point(0.0, 2.0, 1.0) ≈ at(top_left_ray, 1.0)
            @test Point(0.0, -2.0, -1.0) ≈ at(bottom_right_ray, 1.0)
        end

        # Do the tests
        for test in [test1, test2, test3]
            test(setup())
        end

    end
end

@testset "Shapes" begin
    @testset "Plane" begin
        # xy-plane and incoming orthogonal ray from above
        ray_above = Ray(Point(1., 2., 3.), Vec(0., 0., -1.))
        hr_above = HitRecord(
            Point(1., 2., 0.),
            Normal(0., 0., 1.),
            Vec2D(0., 0.),
            3.,
            ray_above)
        test_intersection(Plane(), ray_above, hr_above)
        # xy-plane and incoming 45° ray from below
        ray_diag = Ray(Point(1., 1., -1.), Vec(-1., -1., 1.))
        hr_diag = HitRecord(
            Point(0., 0., 0.),
            Normal(0., 0., -1.),
            Vec2D(0., 0.),
            1.,
            ray_diag
        )
        test_intersection(Plane(), ray_diag, hr_diag)
        # xy-plane and ray in x-direction: no intersection
        ray_x = Ray(Point(1., 2., 3.), Vec(1., 0., 0.))
        hr_x = nothing
        test_intersection(Plane(), ray_x, hr_x)
        # xz-plane (y=0) and ray in y-direction: intersection;
        # test also 2D coordinates.
        ray_y = Ray(Point(0.1, -1., 0.), Vec(0., 1., 0.))
        plane_rotated = Plane(rotation_x(90))
        hr_rotated = HitRecord(
            Point(0.1, 0., 0.),
            Normal(0., -1., 0.),
            Vec2D(0.1, 0.),
            1.,
            ray_y
        )
        test_intersection(Plane(rotation_x(90)), ray_y, hr_rotated)
        # Ray with origin (0,0,2) and direction (0,0,1):
        # xy-plane (z=0): no intersection
        # translated xy-plane (e.g. z=3): intersection
        ray_z = Ray(Point(0., 0., 2.), Vec(0., 0., 1.))
        hr_z0 = nothing
        hr_z3 = HitRecord(
            Point(0., 0., 3.),
            Normal(0., 0., -1.),
            Vec2D(0., 0.),
            1.,
            ray_z
        )
        test_intersection(Plane(), ray_z, hr_z0)
        test_intersection(Plane(translation(Vec(0.,0.,3.))), ray_z, hr_z3)
    end

    @testset "Sphere" begin
        # centered unit sphere
        ## ray from above
        ray_above = Ray(Point(0.,0.,2.), neg(VEC_Z))
        hr_above = HitRecord(
            Point(0., 0., 1.),
            Normal(0., 0., 1.),
            Vec2D(0., 0.),
            1.,
            ray_above)
        test_intersection(Sphere(), ray_above, hr_above)
        ## ray from x
        ray_x = Ray(Point(3.,0.,0.), neg(VEC_X))
        hr_x = HitRecord(
            Point(1., 0., 0.),
            Normal(1., 0., 0.),
            Vec2D(0., 0.5),
            2.,
            ray_x)
        test_intersection(Sphere(), ray_x, hr_x)
        ## ray from Origin towards x
        ray_x = Ray(Point(0.,0.,0.), VEC_X)
        hr_x = HitRecord(
            Point(1., 0., 0.),
            Normal(-1., 0., 0.),
            Vec2D(0., 0.5),
            1.,
            ray_x)
        test_intersection(Sphere(), ray_x, hr_x)
        ## ray from x, no intersection
        ray = Ray(Point(1.5,0.,0.), VEC_X)
        hr = nothing
        test_intersection(Sphere(), ray, hr)
        ## ray from x, no intersection
        ray = Ray(Point(-1.5,0.,1.5), VEC_X)
        hr = nothing
        test_intersection(Sphere(), ray, hr)

        # translated unit sphere
        ## x_transltion, ray from above
        sphere = Sphere(translation(Vec(10.0,0.,0.)))
        ray = Ray(Point(10.,0.,3.), neg(VEC_Z))
        hr = HitRecord(
            Point(10., 0., 1.),
            Normal(0., 0., 1.),
            Vec2D(0., 0.),
            2.,
            ray)
        test_intersection(sphere, ray, hr)
        ## x_transltion, ray from above, no intersections
        sphere = Sphere(translation(Vec(10.0,0.,0.)))
        ray = Ray(Point(0.,0.,3.), neg(VEC_Z))
        hr = nothing
        test_intersection(sphere, ray, hr)
        ## x_transltion, no intersections
        sphere = Sphere(translation(Vec(10.0,0.,0.)))
        ray = Ray(Point(1.,1.,1.), Vec(-1.,-1.,-1.))
        hr = nothing
        test_intersection(sphere, ray, hr)

        #rotated unit sphere
        ## 45° z rotation, ray from x_pos
        sphere = Sphere(rotation_z(45))
        ray = Ray(Point(14.,0.,0.), neg(VEC_X))
        hr = HitRecord(
            Point(1., 0., 0.),
            Normal(1., 0., 0.),
            Vec2D(0.875, 0.5),
            13.,
            ray)
        test_intersection(sphere, ray, hr)
        ## WORK IN PROGRESS_________________________________
        # -45° z rotation, *2 uniform scaling
        ## ray from 45° angle from every axes
        # rotation_z(-45)*scaling(2., 2., 2.)
        #=
        sphere = Sphere(scaling(2., 2., 2.))
        d = 2/sqrt(3)
        ray = Ray(Point(2*d,2*d,2*d), Vec(-1.,-1.,-1.))
        hr = HitRecord(
            Point(d, d, d),
            Normal(d, d, d),
            Vec2D(0.125, acos(d/2)/π),
            d,
            ray)
        test_intersection(sphere, ray, hr)
        #____________________________________________________
        
        =#
    end
end
