
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
- `depth::Integer`: Allowed number of recursive calls (reflections / refractions).
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
) where {T<:AbstractFloat}
    Ray{T}(origin, dir, tmin, tmax, depth)
end

function ≈(ray1::Ray, ray2::Ray)
    return ray1.origin ≈ ray2.origin && ray1.dir ≈ ray2.dir
end

"Compute the position of a ray at the given t."
function at(ray::Ray, t::AbstractFloat)
    # r(t) = O + t ⋅ d;
    # O is a Point, d a vector and t a scalar.
    return ray.origin + t * ray.dir
end

"Apply a transformation to a ray."
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
    aspect_ratio::Union{Rational,T}
    transformation::Transformation
end

# Default constructor with implicit transformation (identity)
function OrthogonalCamera(aspect_ratio::Union{Rational,T}) where {T<:AbstractFloat}
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

# Perspective Camera
struct PerspectiveCamera{T<:AbstractFloat} <: Camera{T}
    distance::T
    aspect_ratio::Union{Rational,T}
    transformation::Transformation
end

# Default constructor with implicit transformation (identity)
function PerspectiveCamera(aspect_ratio::Union{Rational,T}) where {T<:AbstractFloat}
    distance = 1
    transformation =
        Transformation(HomMatrix(IDENTITY_MATR4x4), HomMatrix(IDENTITY_MATR4x4))
    PerspectiveCamera{T}(distance, aspect_ratio, transformation)
end

function fire_ray(cam::PerspectiveCamera, u::AbstractFloat, v::AbstractFloat)
    x = -cam.distance
    y = 0.0
    z = 0.0
    origin = Point(x, y, z)
    dir = Vec(cam.distance, (1.0 - 2.0 * u) * cam.aspect_ratio, 2.0 * v - 1.0)
    ray = Ray(origin, dir)
    return transform(ray, cam.transformation)
end

# ─────────────────────────────────────────────────────────────
# ImageTracer

# - fire_ray: sends a ray to a given pixel
# - fire_all_rays: iterates over all pixels and calls fire_ray
# ─────────────────────────────────────────────────────────────

"""
    ImageTracer{T}

Responsible for:
- Sending rays to the corresponding pixels in an image
- Converting between `HdrImage.pixels` indices `(column, row)` and the camera's `(u, v)` coordinates

# Fields
- `image::HdrImage`: the image to write ray results into
- `camera::Camera{T}`: the camera generating the rays
"""
struct ImageTracer{T<:AbstractFloat}
    image::HdrImage
    camera::Camera{T}
end

"""
    fire_ray(tracer::ImageTracer, col::Integer, row::Integer; u_pixel::AbstractFloat=0.5, v_pixel::AbstractFloat=0.5)

Convert the pixel coordinates `(col, row)` to screen coordinates `(u, v)`

Generates a `Ray` directed towards a specific point on the pixel's surface of the image in `tracer` 

# Arguments
- `tracer::ImageTracer`: An object containing the camera and the image.
- `col::Integer`: The pixel column (starting from 1).
- `row::Integer`: The pixel row (starting from 1).
- `u_pixel::AbstractFloat=0.5`: Horizontal position in the pixel (range 0 to 1).
- `v_pixel::AbstractFloat=0.5`: Vertical position in the pixel (range 0 to 1).

# Returns
- A `Ray` generated from the camera towards the specified point within the pixel.

# Example
    ray = fire_ray(tracer, 100, 150) # center of pixel
    ray = fire_ray(tracer, 100, 150; u_pixel=0.25, v_pixel=0.75)  # custom point in the pixel
"""
function fire_ray(
    tracer::ImageTracer{T},
    col::Integer,
    row::Integer;
    u_pixel::T = 0.5,
    v_pixel::T = 0.5,
) where {T<:AbstractFloat}

    # all pixels have dimensions '(1,1)', so the pixel center is at the pixel coordinates '+ (0.5,0.5)'
    # !!Attention!!
    #         the coordinates of the pixel(row, col) are:        |        but the (u,v) coordinates are:
    #      (col=1, row=1)  +--------+   (col=width, row=1)       |   (u=0, v=1)    +--------+    (u=1, v=1)
    #                      |        |                            |                 |        |
    #                      |        |                            |                 |        |
    # (col=1, row=height)  +--------+   (col=width, row=height)  |   (u=0, v=0)    +--------+    (u=1, v=0)
    #=

    u = (col - 1 + u_pixel) / (tracer.image.width)
    v = 1 + (v_pixel - row) / (tracer.image.height)

    =#

    u = (col - 1 + u_pixel) / (tracer.image.width)
    v = 1 - (row - 1 + v_pixel) / (tracer.image.height)
    return fire_ray(tracer.camera, u, v)
end


"""
    fire_all_rays!(tracer::ImageTracer, func)

Calculate the solution to the rendering equation with a specified method for all pixels in an image

Set all images pixels to calculated colors

# Arguments
- `tracer::ImageTracer`: An object containing the camera and the image.
- `func`: The function that resolve the rendering equation for one pixel

The function set all the pixels of the passed `HdrImage` to calculated colors.
"""
function fire_all_rays!(tracer::ImageTracer, func)
    for row = 1:tracer.image.height
        for col = 1:tracer.image.width
            ray = fire_ray(tracer, col, row) # if i want i can pass u_pixel and v_pixel ≠ 0.5 (default value)
            color = func(ray)
            set_pixel!(tracer.image, col, row, color)
        end
    end
end
