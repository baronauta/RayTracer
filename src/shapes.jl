""" 
Abstract base type for geometric shapes.

Subtypes:
- `Sphere`
- `Plane`
"""
abstract type Shape{T<:AbstractFloat} end

"""
Stores information about a ray's intersection with a shape.
- `world_point::Point`: 3D point where the intersection occurred;
- `normal::Normal`: surface normal at the intersection;
- `surface_point::Vec2D`: (u,v) coordinates of the intersection;
- `t`: ray parameter associated with the intersection;
- `ray::Ray`: the light ray that caused the intersection.
"""
struct HitRecord{T<:AbstractFloat}
    world_point::Point{T}
    normal::Normal{T}
    surface_point::Vec2D{T}
    t::T
    ray::Ray{T}
end

"Compare two `HitRecord` types. Useful for tests."
function ≈(hr1::Union{HitRecord, Nothing}, hr2::Union{HitRecord, Nothing})
    if isnothing(hr1) || isnothing(hr2)
        return hr1 == hr2
    else        
        hr1.world_point ≈ hr2.world_point &&
        hr1.normal ≈ hr2.normal &&
        hr1.surface_point ≈ hr2.surface_point &&
        hr1.t ≈ hr2.t
    end
end

"""
Adjust surface normal to face against the incoming ray direction.
Ensures dot(n, d) < 0.
"""
function _adjustnormal(normal::Normal, ray::Ray)
    dot(normal, ray.dir) < 0 ? normal : -1 * normal
end

"""
Define a xy-plane (z=0) and associate a transformation to it.
"""
struct Plane{T<:AbstractFloat} <: Shape{T}
    transformation::Transformation{T}
end

"Define a xy-plane (z=0). Associated transformation is identity."
function Plane()
    transformation =
        Transformation(HomMatrix(IDENTITY_MATR4x4), HomMatrix(IDENTITY_MATR4x4))
    Plane(transformation)
end

"""
Checks if a ray intersects the plane.
Return a `HitRecord`, or `nothing` if no intersection was found.
"""
function ray_intersection(plane::Plane, ray::Ray)
    # First, consider the ray in the frame of reference
    # of the plane, i.e. use the inverse transformation
    # associated to the considered shape.
    inv_ray = transform(ray, inverse(plane.transformation))

    # Ray is parallel to the xy-plane (z=0): no intersection
    if inv_ray.dir.z == 0
        return nothing
    end

    # Given a ray r(t) = O + t ⋅ d,
    # where O is the origin (Point) and d the direction (Vec),
    # its intersection with the xy-plane (z=0) is
    # O.z + t ⋅ d.z = 0 ⇒ t = - O.z / d.z.
    t = -inv_ray.origin.z / inv_ray.dir.z

    if (t <= inv_ray.tmin) || (t >= inv_ray.tmax)
        return nothing
    end

    hit_point = at(inv_ray, t)
    # To find intersection point in the real space,
    # change reference of frame to the world one
    # using the transformation associated to the shape.
    world_point = plane.transformation * hit_point
    # Normal to xy-plane is e_z = (0,0,1)
    normal = plane.transformation * _adjustnormal(Normal(0.0, 0.0, 1.0), inv_ray)
    # The plane is parameterized with periodic conditions:
    # u = p.x - ⌊p.x⌋ and v = p.y - ⌊p.y⌋,
    # where ⌊⋅⌋ is the floor function, so that u,v∈[0,1).
    surface_point =
        Vec2D(hit_point.x - floor(hit_point.x), hit_point.y - floor(hit_point.y))

    return HitRecord(world_point, normal, surface_point, t, ray)
end
