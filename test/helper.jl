# add methods to this function of Base
import RayTracer: +, -, *, ≈, write, show
# from colors.jl
import RayTracer: HdrImage
# from geometry.jl
import RayTracer: Point, Vec, Vec2D, Normal, dot, cross, norm, squared_norm
# from cameras.jl
import RayTracer: Ray
# from shapes.jl
import RayTracer: Shape, Plane, ray_intersection

function test_intersection(s::Shape, r::Ray, wp::Point, n::Normal, sp::Vec2D, t::AbstractFloat)
    hitrecord = ray_intersection(s, r)
    @test hitrecord.world_point ≈ wp
    @test hitrecord.normal ≈ n
    @test hitrecord.surface_point ≈ sp
    @test hitrecord.t ≈ t
end