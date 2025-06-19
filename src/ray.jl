#     __________________________________________________________
#
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

"""
    Ray(origin::Point{T}, dir::Vec{T}, tmin::T, tmax::T, depth::Integer) where {T<:AbstractFloat}

Represents a ray in 3D space.

# Arguments
- `origin::Point{T}`: The starting point of the ray in 3D space.
- `dir::Vec{T}`: The direction vector of the ray.
- `tmin::T`: The minimum parameter along the ray.
- `tmax::T`: The maximum parameter along the ray.
- `depth::Integer`: Allowed number of recursive calls (reflections / refractions).
"""
struct Ray{T<:AbstractFloat}
    origin::Point{T}
    dir::Vec{T}
    tmin::T
    tmax::T
    depth::Integer
end

"""
    Ray(origin, dir; tmin=1e-5, tmax=typemax(T), depth=0)

Create a 3D ray from `origin` in direction `dir`, with optional bounds and recursion depth set to zero.
"""
function Ray(
    origin::Point{T},
    dir::Vec{T};
    tmin::T = 1e-5,
    tmax::T = typemax(T),
    depth::Integer = 0,
) where {T<:AbstractFloat}
    Ray{T}(origin, dir, tmin, tmax, depth)
end

"Check if two rays are approximately equal"
function ≈(ray1::Ray, ray2::Ray)
    return ray1.origin ≈ ray2.origin && ray1.dir ≈ ray2.dir
end

"Compute the position of a ray at the given t"
function at(ray::Ray, t::AbstractFloat)
    # r(t) = O + t ⋅ d;
    # O is a Point, d a vector and t a scalar.
    return ray.origin + t * ray.dir
end

"Apply a transformation to a ray"
function transform(ray::Ray, T::Transformation)
    origin = T * ray.origin
    dir = T * ray.dir
    return Ray(origin, dir)
end