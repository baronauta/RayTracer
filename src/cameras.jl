# ─────────────────────────────────────────────────────────────
# 
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
mutable struct Ray{T<:AbstractFloat}
    origin::Point{T}
    dir::Vec{T}
    tmin::T
    tmax::T
    depth::Integer
end


# Outer constructor with defaults
function Ray(origin::Point{T}, dir::Vec{T}; tmin::T=1e-5, tmax::T=typemax(T), depth::Integer=0) where {T}
    Ray{T}(origin, dir, tmin, tmax, depth)
end

function ≈(ray1::Ray, ray2::Ray)
    return ray1.origin ≈ ray2.origin && ray1.dir ≈ ray2.dir
end

function at(ray::Ray, t::AbstractFloat)
    # r(t) = O + t ⋅ d, where O is a Point, d a vector and t a scalar
    return ray.origin + t * ray.dir 
end

function transform(ray::Ray, T::Transformation)
    origin = T * ray.origin
    dir = T * ray.dir
    return Ray(origin, dir)
end

# ─────────────────────────────────────────────────────────────
# 
# ─────────────────────────────────────────────────────────────

abstract type Camera{T<:AbstractFloat} end

struct OrthogonalCamera{T<:AbstractFloat} <: Camera{T}

end

struct PerspectiveCamera{T<:AbstractFloat} <: Camera{T}

end