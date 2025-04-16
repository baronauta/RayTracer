# ─────────────────────────────────────────────────────────────
# Ray
# ─────────────────────────────────────────────────────────────

"""
    Ray(origin::Point{T}, dir::Vec{T}, tmin::T, tmax::T, depth::Integer) where {T<:AbstractFloat}

Represents a ray in 3D space.

# Arguments
- `origin::Point{T}`: The starting point of the ray in 3D space.
- `dir::Vec{T}`: The direction vector of the ray.
- `tmin::T`: The minimum parameter along the ray.
- `tmax::T`: The maximum parameter along the ray.
- `depth::Integer`: The recursion depth of the ray, useful in ray tracing to limit the number of recursive calls (e.g., for reflections/refractions).

# Type Parameters
- `T<:AbstractFloat`: The numeric type used for coordinates and ray parameters, usually `Float32` or `Float64`.
"""
struct Ray{T<:AbstractFloat}
    origin::Point{T}
    dir::Vec{T}
    tmin::T
    tmax::T
    depth::Integer
end


# Outer constructor with defaults
function Ray(
    origin::Point{T},
    dir::Vec{T};
    tmin::T = 1e-5,
    tmax::T = typemax(T),
    depth::Integer = 0,
) where {T}
    Ray{T}(origin, dir, tmin, tmax, depth)
end

function ≈(ray1::Ray, ray2::Ray)
    return ray1.origin ≈ ray2.origin && ray1.dir ≈ ray2.dir
end

function at(ray::Ray, t::AbstractFloat)
    # r(t) = O + t ⋅ d;
    # O is a Point, d a vector and t a scalar.
    return ray.origin + t * ray.dir
end

function transform(ray::Ray, T::Transformation)
    origin = T * ray.origin
    dir = T * ray.dir
    return Ray(origin, dir)
end

# ─────────────────────────────────────────────────────────────
# Camera
# - OrthogonalCamera
# - PerspectiveCamera
#
# Spatial coordinates are named with (x, y, z).
# Screen coordinates are named (u,v).
# ─────────────────────────────────────────────────────────────

abstract type Camera{T<:AbstractFloat} end

#Orthogonal Camera
struct OrthogonalCamera{T<:AbstractFloat} <: Camera{T}
    aspect_ratio::Union{Rational{Int64},T}
    transformation::Transformation
end

# Default constructor with implicit transformation (identity)
function OrthogonalCamera(aspect_ratio::Union{Rational{Int64},T}) where {T<:AbstractFloat}
    transformation =
        Transformation(HomMatrix(IDENTITY_MATR4x4), HomMatrix(IDENTITY_MATR4x4))
    OrthogonalCamera{T}(aspect_ratio, transformation)
end

function fire_ray(cam::OrthogonalCamera, u::AbstractFloat, v::AbstractFloat)
    x = -1.0
    y = (1.0 - 2.0 * u) * cam.aspect_ratio
    z = 2.0 * v - 1.0
    origin = Point(x, y, z)
    dir = VEC_X
    ray = Ray(origin, dir)
    return transform(ray, cam.transformation)
end

# Prospective Camera
struct PerspectiveCamera{T<:AbstractFloat} <: Camera{T} 
    distance::AbstractFloat
    aspect_ratio::Union{Rational{Int64},T}
    transformation::Transformation
end

# Default constructor with implicit transformation (identity)
function PerspectiveCamera(aspect_ratio::Union{Rational{Int64},T}) where {T<:AbstractFloat}
    distance = 1.0
    transformation =
        Transformation(HomMatrix(IDENTITY_MATR4x4), HomMatrix(IDENTITY_MATR4x4))
    PerspectiveCamera{T}(distance, aspect_ratio, transformation)
end

function fire_ray(cam::PerspectiveCamera, u::AbstractFloat, v::AbstractFloat)
    x = - cam.distance
    y = 0.0
    z = 0.0
    origin = Point(x, y, z)
    dir = Vec(cam.distance, (1.0 - 2.0 * u) * cam.aspect_ratio, 2.0 * v - 1.0)
    ray = Ray(origin, dir)
    return transform(ray, cam.transformation)
end