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
