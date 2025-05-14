# add methods to this function of Base
import RayTracer: +, -, *, ≈, write, show
# constant
import RayTracer: IS_LITTLE_ENDIAN, HOST_ENDIANNESS
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
import RayTracer: write_color, read_pfm_image, _parse_endianness, _parse_img_size
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
import RayTracer: Shape, Plane, Sphere, HitRecord, ray_intersection
# from world.jl
import RayTracer: World, add!, ray_intersection
function test_intersection(
    s::Union{Shape,World},
    r::Ray,
    expected_hr::Union{HitRecord,Nothing},
)
    hitrecord = ray_intersection(s, r)
    @test hitrecord ≈ expected_hr
end
