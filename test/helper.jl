# add methods to this function of Base
import RayTracer: +, -, *, ≈, write, show
# from colors.jl
import RayTracer:
    RGB,
    HdrImage,
    get_pixel,
    set_pixel!,
    luminosity,
    normalize_image!,
    clamp_image!,
    log_average
# from io.jl
import RayTracer: read_pfm_image, _parse_endianness, _parse_img_size, little_endian
# from geometry.jl
import RayTracer:
    Point,
    Vec,
    Vec2D,
    Normal,
    dot,
    cross,
    norm,
    squared_norm,
    vec_to_normal,
    point_to_vec,
    neg,
    VEC_X,
    VEC_Y,
    VEC_Z
# from transformation.jl
import RayTracer:
    HomMatrix,
    Transformation,
    _is_consistent,
    translation,
    rotation_x,
    rotation_y,
    rotation_z,
    scaling
# from cameras.jl
import RayTracer:
    Ray,
    at,
    transform,
    PerspectiveCamera,
    OrthogonalCamera,
    ImageTracer,
    fire_ray,
    fire_all_rays!
# from shapes.jl
import RayTracer: Shape, Plane, ray_intersection

function test_intersection(
    s::Shape,
    r::Ray,
    wp::Point,
    n::Normal,
    sp::Vec2D,
    t::AbstractFloat,
)
    hitrecord = ray_intersection(s, r)
    @test hitrecord.world_point ≈ wp
    @test hitrecord.normal ≈ n
    @test hitrecord.surface_point ≈ sp
    @test hitrecord.t ≈ t
end
