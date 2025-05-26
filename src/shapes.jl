abstract type Shape{T<:AbstractFloat} end

"""
Stores information about a ray's intersection with a shape.
- `world_point::Point`: 3D point where the intersection occurred;
- `normal::Normal`: surface normal at the intersection;
- `surface_point::Vec2D`: (u,v) coordinates of the intersection;
- `t`: ray parameter associated with the intersection;
- `ray::Ray`: the light ray that caused the intersection.
- `shape::Shape`: the object intersected by the ray
"""
struct HitRecord{T<:AbstractFloat}
    world_point::Point{T}
    normal::Normal{T}
    surface_point::Vec2D{T}
    t::T
    ray::Ray{T}
    shape::Shape{T}
end

"Compare two `HitRecord` types. Useful for tests." # ⚠️ how to compare shapes??
function ≈(hr1::Union{HitRecord,Nothing}, hr2::Union{HitRecord,Nothing})
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

# ─────────────────────────────────────────────────────────────
# Plane definition and functions
# ─────────────────────────────────────────────────────────────

"""
Define a xy-plane (z=0) with an associated transformation and material.
"""
struct Plane{T<:AbstractFloat} <: Shape{T}
    transformation::Transformation{T}
    material::Material
end

"Define a xy-plane (z=0). Associated transformation is identity, material is default material."
function Plane()
    transformation =
        Transformation(HomMatrix(IDENTITY_MATR4x4), HomMatrix(IDENTITY_MATR4x4))
    material = Material()
    Plane(transformation, material)
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

    return HitRecord(world_point, normal, surface_point, t, ray, plane)
end


# ─────────────────────────────────────────────────────────────
# Sphere definition and functions
# ─────────────────────────────────────────────────────────────

"""
Define a 3D unit sphere centered on the origin of the axes
with an associated transformation and material.
"""
struct Sphere{T<:AbstractFloat} <: Shape{T}
    transformation::Transformation{T}
    material::Material
end

"""
Define a 3D unit sphere centered on the origin of the axes.
Associated transformation is identity.
Associated material is a default material
"""
function Sphere()
    transformation =
        Transformation(HomMatrix(IDENTITY_MATR4x4), HomMatrix(IDENTITY_MATR4x4))
    material = Material()
    Sphere(transformation, material)
end

"""
Define a 3D unit sphere centered on the origin of the axes.
Associated transformation is identity.
"""
function Sphere(material)
    transformation =
        Transformation(HomMatrix(IDENTITY_MATR4x4), HomMatrix(IDENTITY_MATR4x4))
    Sphere(transformation, material)
end

"""
Convert a 3D point on the surface of the unit sphere into a (u, v) 2D point
"""
function _sphere_point_to_uv(point::Point)
    u = atan(point.y, point.x) / (2.0 * π)
    v = acos(point.z) / π
    (u ≥ 0) ? Vec2D(u, v) : Vec2D(u + 1, v)
end

"""
Compute the normal of a unit sphere.
The normal is computed for a point (`Point`) on the surface of the
sphere and the right direction is choosen using `_adjustnormal`.
"""
function _sphere_normal(point::Point, ray::Ray)
    _adjustnormal(Normal(point.x, point.y, point.z), ray)
end


"""
Checks if a ray intersects the Sphere.
Return a `HitRecord`, or `nothing` if no intersection was found.
"""
function ray_intersection(sphere::Sphere, ray::Ray)
    # Consider the ray into the sphere frame of reference
    # applying the inverse transformation.
    inv_ray = transform(ray, inverse(sphere.transformation))

    # the equation for sphere intersection is: t^2∥​d∥^​2+2t(O⋅d)+∥​O∥^​2−1=0
    # where O is the ray origin, d the ray direction
    # tangent intersections are not considered, so there are
    # intersections only if Δ > 0.

    # defining reduced Δ:
    # delta ≡ Δ/4 = (O ⋅ d)² − ||d||² ⋅ (||O||² − 1) = b² -a*c
    origin_vec = point_to_vec(inv_ray.origin)
    a = squared_norm(inv_ray.dir)
    b = dot(origin_vec, inv_ray.dir)
    c = squared_norm(origin_vec) - 1.0

    delta = b^2 - a * c
    if delta ≤ 0.0
        return nothing
    end
    # finding the 2 t solutions
    sqrt_delta = sqrt(delta)
    tmin = (-b - sqrt_delta) / (a)
    tmax = (-b + sqrt_delta) / (a)
    # choosing the closest solution
    if inv_ray.tmin < tmin < inv_ray.tmax
        t = tmin
    elseif inv_ray.tmin < tmax < inv_ray.tmax
        t = tmax
    else
        return nothing
    end
    # intersection point into the sphere reference of frame
    hit_point = at(inv_ray, t)

    # traspose the intersection point, normal and 
    # surface point into the original frame of reference.
    world_point = sphere.transformation * hit_point
    normal = sphere.transformation * _sphere_normal(hit_point, inv_ray)
    surface_point = _sphere_point_to_uv(hit_point)

    return HitRecord(world_point, normal, surface_point, t, ray, sphere)
end
