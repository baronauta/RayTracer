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
        @test RayTracer.point_to_vec(p) ≈ Vec(1.0, 2.0, 3.0)
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
        @test -(v) ≈ Vec(-1.0, -2.0, -3.0)
        # Vec dot product, cross product and norm
        @test dot(v, u) ≈ 32.0
        @test cross(v, u) ≈ Vec(-3.0, 6.0, -3.0)
        @test RayTracer.squared_norm(v) ≈ 14.0
        @test RayTracer.norm(v)^2 ≈ 14.0
        @test RayTracer.normalize(v) ≈ Vec(v.x/sqrt(14), v.y/sqrt(14), v.z/sqrt(14))
        # Conversion Vec to Normal
        @test RayTracer.vec_to_normal(v) ≈ Normal(1.0, 2.0, 3.0)
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

@testset "Transformation" begin

    @testset "Consistency" begin
        #! format: off
        m = Matrix{Float32}([
            1.0 2.0 3.0 4.0
            5.0 6.0 7.0 8.0
            9.0 9.0 8.0 7.0
            6.0 5.0 4.0 1.0
        ])
        invm = Matrix{Float32}([
            -3.75    2.75   -1.0    0.0
            4.375  -3.875   2.0   -0.5
            0.5     0.5    -1.0    1.0
            -1.375   0.875   0.0   -0.5
        ])
        #! format: on
        T = Transformation(HomMatrix(m), HomMatrix(invm))
        @test RayTracer._is_consistent(T)
        # Create a copy of the matrices so that each Transformation has its own copy of the data
        T1 = Transformation(HomMatrix(copy(m)), HomMatrix(copy(invm)))
        T2 = Transformation(HomMatrix(copy(m)), HomMatrix(copy(invm)))
        T3 = Transformation(HomMatrix(copy(m)), HomMatrix(copy(invm)))
        @test T ≈ T1
        # Change one element of T.M: this makes T not consistent
        T2.M.matrix[1, 1] += 1
        @test !(T ≈ T2)
        @test !(RayTracer._is_consistent(T2))
        # Change one element of T.invM: this makes T not consistent
        T3.invM.matrix[1, 3] += 1
        @test !(T ≈ T3)
        @test !(RayTracer._is_consistent(T3))
    end

    @testset "Multiplication" begin
        #! format: off
        m1 = Matrix{Float32}([
            1.0 2.0 3.0 4.0
            5.0 6.0 7.0 8.0
            9.0 9.0 8.0 7.0
            6.0 5.0 4.0 1.0
        ])
        invm1 = Matrix{Float32}([
            -3.75    2.75   -1.0    0.0
            4.375  -3.875   2.0   -0.5
            0.5     0.5    -1.0    1.0
            -1.375   0.875   0.0   -0.5
        ])
        #! format: on
        T1 = Transformation(HomMatrix(m1), HomMatrix(invm1))
        @test RayTracer._is_consistent(T1)
        #! format: off
        m2 = Matrix{Float32}([
            3.0 5.0 2.0 4.0
            4.0 1.0 0.0 5.0
            6.0 3.0 2.0 0.0
            1.0 4.0 2.0 1.0
        ])
        invm2 = Matrix{Float32}([
            0.4  -0.2   0.2  -0.6
            2.9  -1.7   0.2  -3.1
            -5.55  3.15 -0.4   6.45
            -0.9   0.7  -0.2   1.1
        ])
        #! format: on
        T2 = Transformation(HomMatrix(m2), HomMatrix(invm2))
        @test RayTracer._is_consistent(T2)
        #! format: off
        expected_m = Matrix{Float32}([
            33.0   32.0  16.0  18.0
            89.0   84.0  40.0  58.0
            118.0  106.0  48.0  88.0
            63.0   51.0  22.0  50.0
        ])
        expected_invm = Matrix{Float32}([
            -1.45    1.45  -1.0   0.6
        -13.95   11.95  -6.5   2.6
            25.525 -22.025 12.25 -5.2
            4.825  -4.325  2.5  -1.1
        ])
        #! format: on
        expected = Transformation(HomMatrix(expected_m), HomMatrix(expected_invm))
        @test RayTracer._is_consistent(expected)

        prod = T1 * T2
        @test expected ≈ prod
    end

    @testset "× Vec/Point/Normal" begin
        #! format: off
        m_mat = Matrix{Float32}([
            1.0  2.0  3.0  4.0
            5.0  6.0  7.0  8.0
            9.0  9.0  8.0  7.0
            0.0  0.0  0.0  1.0
        ])
        invm_mat = Matrix{Float32}([
        -3.75   2.75  -1.0   0.0
            5.75  -4.75   2.0   1.0
        -2.25   2.25  -1.0  -2.0
            0.0    0.0    0.0   1.0
        ])
        #! format: off
        T = Transformation(HomMatrix(m_mat), HomMatrix(invm_mat))
        @test RayTracer._is_consistent(T)

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
        @test RayTracer._is_consistent(tr1)
        tr2 = translation(Vec(4.0, 6.0, 8.0))
        @test RayTracer._is_consistent(tr2)
        prod = tr1 * tr2
        @test RayTracer._is_consistent(prod)
        expected = translation(Vec(5.0, 8.0, 11.0))
        @test prod ≈ expected
    end

    @testset "Rotations" begin
        @test RayTracer._is_consistent(rotation_x(0.1))
        @test RayTracer._is_consistent(rotation_y(0.1))
        @test RayTracer._is_consistent(rotation_z(0.1))
        @test (rotation_x(90) * VEC_Y) ≈ VEC_Z
        @test (rotation_y(90) * VEC_Z) ≈ VEC_X
        @test (rotation_z(90) * VEC_X) ≈ VEC_Y
    end

    @testset "Scaling" begin
        tr1 = scaling(2.0, 5.0, 10.0)
        @test RayTracer._is_consistent(tr1)
        tr2 = scaling(3.0, 2.0, 4.0)
        @test RayTracer._is_consistent(tr2)
        prod = tr1 * tr2
        @test RayTracer._is_consistent(prod)
        expected = scaling(6.0, 10.0, 40.0)
        @test prod ≈ expected
    end
end

@testset "ONB" begin
    # Random testing
    # 1. Define a vector with random components;
    # 2. Compute the ONB from the normalized vector;
    # 3. Check that that the returned vectors are normalized and orthogonal.
    # ... repeat with different random initialization.
    pcg = RayTracer.PCG()

    for i in 1:100
        v = Vec(RayTracer.random_float!(pcg), RayTracer.random_float!(pcg), RayTracer.random_float!(pcg)) 
        normal = RayTracer.normalize(v)
        e1, e2, e3 = RayTracer.onb_from_z(normal)

        # onb_from_z should return the input normalized vector as e3
        @test e3 ≈ normal
        
        # Orthogonality, i.e. eᵢ ⋅ eⱼ = δᵢⱼ
        @test isapprox(dot(e1, e2), 0, rtol=1e-5, atol=1e-5)
        @test isapprox(dot(e1, e3), 0, rtol=1e-5, atol=1e-5)
        @test isapprox(dot(e2, e3), 0, rtol=1e-5, atol=1e-5)

        # Normalization, i.e. ||eᵢ||² = 1
        @test RayTracer.squared_norm(e1) ≈ 1
        @test RayTracer.squared_norm(e2) ≈ 1
        @test RayTracer.squared_norm(e2) ≈ 1

        # Right-hand triad
        @test RayTracer.cross(e1, e2) ≈ e3
        @test RayTracer.cross(e2, e3) ≈ e1
        @test RayTracer.cross(e3, e1) ≈ e2
    end
end