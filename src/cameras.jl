
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
    ray_for_pixel::Integer
    pcg::PCG
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
    tracer::ImageTracer,
    col::Integer,
    row::Integer;
    u_pixel::AbstractFloat = 0.5,
    v_pixel::AbstractFloat = 0.5,
)

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
    simple_progress_bar(i, total; width=40)

Display a simple progress bar in the terminal.

# Arguments
- `i::Int`: Current iteration number.
- `total::Int`: Total number of iterations.
- `item::String`: type of item for iteration (for video: frame, for image: row; default: row)
- `width::Int=40`: Width of the progress bar in characters (default: 40).

Displays a colored progress bar with percentage and iteration count.
"""
function simple_progress_bar(i, total; item = "row", width = 40)
    # calculate the preogress as fraction of done/total, then calculate the % to indicate aside the bar.
    progress = i / total # the fraction o
    percent = round(progress * 100; digits = 1)

    # calculate the number of space and the number of special caracter to fill the bar.
    filled = round(Int, progress * width)
    empty = width - filled

    # To print a green block:
    # \e[32m█  → enter terminal graphics mode, set text color to green, and print the "█" character
    # \e[0m    → reset terminal style to default
    bar = repeat("\e[32m█\e[0m", filled) * repeat(" ", empty)
    print("\r[$bar] $percent% (generating $item n. $i / $total)")

    # Julia keeps output in a buffer to print multiple things at once for efficiency.
    # Not needed in this case — I want the progress bar to update in real time.
    # Forces immediate output to the terminal by flushing the output buffer.
    flush(stdout)
end

function is_square(n::Integer) 
    # `isqrt(n)`: returns the largest integer m such that m*m <= n
    # Ex: isqrt(12) = 3
    return isqrt(n)^2 == n
end

struct AntialiasingError <: CustomException
    msg::String
end


"""
    fire_all_rays!(tracer::ImageTracer, func; progress_flag = true)

Calculate the solution to the rendering equation with a specified method for all pixels in an image

Set all images pixels to calculated colors

# Arguments
- `tracer::ImageTracer`: An object containing the camera and the image.
- `func`: The function that resolve the rendering equation for one pixel
- `progress_flag::Bool`: If `true`, display a progress bar during rendering (default: true).

The function set all the pixels of the passed `HdrImage` to calculated colors.
"""
function fire_all_rays!(tracer::ImageTracer, func; samples_per_pixel=1, pcg=nothing, progress_flag = true)

    sqrt_samples = round(Int, sqrt(samples_per_pixel))  # assume square grid
    if !is_square(samples_per_pixel)
        throw(AntialiasingError("'samples_per_pixel' must be a perfect square (e.g., 1, 4, 9, 16, ...)"))
    end

    for row = 1:tracer.image.height
        for col = 1:tracer.image.width

            if samples_per_pixel==1
                ray = fire_ray(tracer, col, row) # if i want i can pass u_pixel and v_pixel ≠ 0.5 (default value)
                color = func(ray)
                set_pixel!(tracer.image, col, row, color)
            else
                accumulated_color = RGB(0, 0, 0)
                for i = 1:sqrt_samples
                    for j = 1:sqrt_samples
                        # Jittered offset within the subpixel
                        du = (i - random_float!(pcg)) / sqrt_samples
                        dv = (j - random_float!(pcg)) / sqrt_samples
                        ray = fire_ray(tracer, col, row; u_pixel=du, v_pixel=dv)
                        accumulated_color += func(ray)
                        averaged_color = accumulated_color * inv_samples
                        set_pixel!(tracer.image, col, row, averaged_color)
                    end
                end
            end
        end

    end
    # for video i dont want a progress bar for all rows of all images, only for frames.
    # so i need  the progress_flag, if is an image the progress_flag is true, if video is false
    (progress_flag == true) && simple_progress_bar(row, tracer.image.height) # display the progress bar

end