
#_______________________________________________________________________________________
#     LICENSE NOTICE: European Union Public Licence (EUPL) v.1.2
#     __________________________________________________________
#
#   This file is licensed under the European Union Public Licence (EUPL), version 1.2.
#
#   You are free to use, modify, and distribute this software under the conditions
#   of the EUPL v.1.2, as published by the European Commission.
#
#   Obligations include:
#     - Retaining this notice and the licence terms
#     - Providing access to the source code
#     - Distributing derivative works under the same or a compatible licence
#
#   Full licence text: see the LICENSE file or visit https://eupl.eu
#
#   Disclaimer:
#     Unless required by applicable law or agreed to in writing,
#     this software is provided "AS IS", without warranties or conditions
#     of any kind, either express or implied.
#
#_______________________________________________________________________________________


# ─────────────────────────────────────────────────────────────
# Shape type and functions
# ─────────────────────────────────────────────────────────────

""" 
A generic abstract shape.
"""
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

function Plane(material::Material)
    transformation =
        Transformation(HomMatrix(IDENTITY_MATR4x4), HomMatrix(IDENTITY_MATR4x4))
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
Computes intersection parameters for a ray-sphere intersection.

Returns `t₁`, `t₂`, and the transformed ray if an intersection occurs, or `nothing` otherwise.
"""
function _sphere_ray_intersection(sphere::Sphere, ray::Ray)
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
    return tmin, tmax, inv_ray
end


"""
Checks if a ray intersects the Sphere.
Return a `HitRecord`, or `nothing` if no intersection was found.
"""
function ray_intersection(sphere::Sphere, ray::Ray)

    # find the 2 intersection point
    intersection = _sphere_ray_intersection(sphere, ray)
    isnothing(intersection) && (return nothing)
    tmin, tmax, inv_ray = intersection

    # choose the right intersection
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


"""
Checks if a ray intersects the Sphere.
Return a sorted list of all `HitRecord`s or a list of `nothing` if no intersection is found.
"""
function all_ray_intersections(sphere::Sphere, ray::Ray)

    # find the 2 intersection point
    intersection = _sphere_ray_intersection(sphere, ray)
    isnothing(intersection) && (return [nothing])
    tmin, tmax, inv_ray = intersection

    # evaluate hitrecords and return a valid list

    # [hit1, hit2]
    if (inv_ray.tmin < tmin < inv_ray.tmax)
        hit_point1 = at(inv_ray, tmin)
        hit_point2 = at(inv_ray, tmax)
        world_point1 = sphere.transformation * hit_point1
        normal1 = sphere.transformation * _sphere_normal(hit_point1, inv_ray)
        surface_point1 = _sphere_point_to_uv(hit_point1)
        world_point2 = sphere.transformation * hit_point2
        normal2 = sphere.transformation * _sphere_normal(hit_point2, inv_ray)
        surface_point2 = _sphere_point_to_uv(hit_point2)
        hit1 = HitRecord(world_point1, normal1, surface_point1, tmin, ray, sphere)
        hit2 = HitRecord(world_point2, normal2, surface_point2, tmax, ray, sphere)

        # [nothing, hit2]
    elseif !(inv_ray.tmin < tmin < inv_ray.tmax) && (inv_ray.tmin < tmax < inv_ray.tmax)
        hit_point2 = at(inv_ray, tmax)
        world_point2 = sphere.transformation * hit_point2
        normal2 = sphere.transformation * _sphere_normal(hit_point2, inv_ray)
        surface_point2 = _sphere_point_to_uv(hit_point2)
        hit2 = HitRecord(world_point2, normal2, surface_point2, tmax, ray, sphere)
        hit1 = nothing

        # [nothing]
    else
        return [nothing]
    end

    return [hit1, hit2]
end

"""
---
Check whether a `Point p` is inside a `Sphere`.
(i.e. the antitransformed point's distance from the origin is < 1).

**Note:** if the flag is true, points on the surface are also accepted.

"""
function is_inside(p::Point, obj::Sphere, flag::Bool)
    inv_p = inverse(obj.transformation) * p
    flag ? (return (norm(point_to_vec(inv_p)) ≤ 1.0)) :
    (return (norm(point_to_vec(inv_p)) < 1.0))
end


# ─────────────────────────────────────────────────────────────
# Cube definition and functions
# ─────────────────────────────────────────────────────────────
struct Cube{T<:AbstractFloat} <: Shape{T}
    transformation::Transformation{T}
    material::Material
end

# ─────────────────────────────────────────────────────────────
# CSG definition and functions
# ─────────────────────────────────────────────────────────────

"""
Enumerated type representing the possible CSG operations:
- `UNION`: the resulting shape includes the volume of both shapes;
- `DIFFERENCE`: the resulting shape includes only the volume of the first shape minus the second;
- `INTERSECTION`: the resulting shape includes only the shared volume between the two shapes.
"""
@enum Operation begin
    UNION
    DIFFERENCE
    INTERSECTION
end

"""
A Constructive Solid Geometry (CSG) shape defined by applying an operation
(`UNION`, `DIFFERENCE`, or `INTERSECTION`) between two shapes.

Fields:
- `obj1::Shape`: the first shape involved in the operation;
- `obj2::Shape`: the second shape involved in the operation;
- `operation::Operation`: the CSG operation to apply.

Notes:
- **Shape order matters**: `obj1 - obj2` is not the same as `obj2 - obj1`.
- **Shapes can be nested CSGs**: both `obj1` and `obj2` may themselves be `CSG` objects.
"""
struct CSG{T<:AbstractFloat} <: Shape{T}
    obj1::Shape
    obj2::Shape
    operation::Operation
end

"""
Compares two shapes for equality.
Returns `true` if the shapes have the same type and same transformations.

Note: Materials are not compared.
"""
function ≈(obj1::Shape, obj2::Shape)
    return ((typeof(obj1) == typeof(obj2)) && (obj1.transformation ≈ obj2.transformation))
end

"""
Compares two CSG shapes for equality.
Returns `true` if the CSGs have the same obj and operations.
"""
function ≈(csg1::CSG, csg2::CSG)
    if (csg1.operation == csg2.operation)
        if csg1.operation == UNION || csg1.operation == INTERSECTION
            a = ((csg1.obj1 == csg2.obj1) && (csg1.obj2 == csg2.obj2))
            b = ((csg1.obj2 == csg2.obj1) && (csg2.obj2 == csg1.obj1))
            return a || b
        elseif csg1.operation == DIFFERENCE
            return ((csg1.obj1 == csg2.obj1) && (csg1.obj2 == csg2.obj2))
        else
            throw(CsgError("undefined operation $(csg1.operation)"))
        end
    else
        return false
    end
end

"""
Checks whether a CSG construction is valid.

Not accepted `csg` with 2 identical overlapped objects.
"""
function valid_csg(csg::CSG)
    (csg.obj1 == csg.obj2) &&
        throw(CsgError("cannot make csg with two overlapped same objects"))
    return true
end

"""
CSG outer costructor.
validates the csg before returning it.
"""
function CSG(obj1::Shape{T}, obj2::Shape{T}, operation::Operation) where {T<:AbstractFloat}
    csg = CSG{T}(obj1, obj2, operation)
    valid_csg(csg)
    return csg
end

"""
Checks if a `Ray` intersects the `CSG`.
Return a sorted list of all `HitRecord`s or a list of `nothing` if no intersection is found.
"""
function all_ray_intersections(csg::CSG, ray::Ray)

    hit_array_1 = all_ray_intersections(csg.obj1, ray)
    hit_array_2 = all_ray_intersections(csg.obj2, ray)
    real_hits_1 = filter(!isnothing, hit_array_1)
    real_hits_2 = filter(!isnothing, hit_array_2)

    if (!isempty(real_hits_1) && !isempty(real_hits_2))

        # merge and sort simultaniously the 2 array manteining only valid HitRecords
        # ...
        # result = sort_records(real_hits_1, real_hits_2)
        # ...
    else
        return [nothing]
    end
    return # result
end
