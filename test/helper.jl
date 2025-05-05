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
import RayTracer: 
    Shape, 
    Plane, 
    Sphere,
    _sphere_point_to_uv,
    _sphere_normal,
    HitRecord, 
    ray_intersection
function test_intersection(s::Shape, r::Ray, expected_hr::Union{HitRecord, Nothing})
    hitrecord = ray_intersection(s, r)
    @test hitrecord ≈ expected_hr
end
