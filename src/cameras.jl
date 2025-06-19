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


# ─────────────────────────────────────────────────────────────
# CAMERA
#
# We define two types of camera:
# - OrthogonalCamera
# - PerspectiveCamera
#
# Each camera has a method `fire_ray` that is used to cast a ray
# from a specified pixel with coordinates (u, v). 
#
# Note:
# Spatial coordinates are named with (x, y, z), while screen 
# coordinates are named (u,v).
# ─────────────────────────────────────────────────────────────


abstract type Camera{T<:AbstractFloat} end


"""
    OrthogonalCamera{T}

Uses orthographic projection, which preserves object sizes regardless of depth.
This is ideal for technical or architectural visualization where true dimensions are important.

# Fields
- `aspect_ratio::Union{Rational,T}`: width-to-height ratio of the view.
- `transformation::Transformation`: transformation to be applied to th camera.
"""
struct OrthogonalCamera{T<:AbstractFloat} <: Camera{T}
    aspect_ratio::Union{Rational,T}
    transformation::Transformation
end

"""
    OrthogonalCamera(aspect_ratio::Union{Rational,T})

Constructs an orthographic camera with the given `aspect_ratio` and identity transformation.
"""
function OrthogonalCamera(aspect_ratio::Union{Rational,T}) where {T<:AbstractFloat}
    transformation =
        Transformation(HomMatrix(IDENTITY_MATR4x4), HomMatrix(IDENTITY_MATR4x4))
    OrthogonalCamera{T}(aspect_ratio, transformation)
end

"""
    fire_ray(cam::OrthogonalCamera, u::AbstractFloat, v::AbstractFloat)

Generates a ray from the orthographic camera through screen coordinates `(u, v)`.

The ray originates at `x = -1` on the image plane and points in the +X direction.
"""
function fire_ray(cam::OrthogonalCamera, u::AbstractFloat, v::AbstractFloat)
    x = -1.0
    y = (1.0 - 2.0 * u) * cam.aspect_ratio
    z = 2.0 * v - 1.0
    origin = Point(x, y, z)
    dir = VEC_X
    ray = Ray(origin, dir)
    return transform(ray, cam.transformation)
end


"""
    PerspectiveCamera{T}

Camera with perspective projection. Objects farther from the camera appear smaller.

# Fields
- `distance::T`: distance of the camera from the image plane (screen).
- `aspect_ratio::Union{Rational,T}`: width-to-height ratio of the view.
- `transformation::Transformation`: transformation to be applied to th camera.
"""
struct PerspectiveCamera{T<:AbstractFloat} <: Camera{T}
    distance::T
    aspect_ratio::Union{Rational,T}
    transformation::Transformation
end

"""
    PerspectiveCamera(aspect_ratio)

Create a perspective camera with the given aspect ratio, default distance = 1, 
and identity transformation.
"""
function PerspectiveCamera(aspect_ratio::Union{Rational,T}) where {T<:AbstractFloat}
    distance = 1
    transformation =
        Transformation(HomMatrix(IDENTITY_MATR4x4), HomMatrix(IDENTITY_MATR4x4))
    PerspectiveCamera{T}(distance, aspect_ratio, transformation)
end

"""
    fire_ray(cam::PerspectiveCamera, u::AbstractFloat, v::AbstractFloat)

Generates a perspective ray through normalized screen coordinates `(u, v)`.

The ray originates at `(-distance, 0, 0)` and points toward the view plane.
"""
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
# IMAGETRACER
#
# ImageTracer binds together the HDR image and the camera.
# The function `fire_ray` is responsible for firing a single ray
# through a specified pixel of the image.
#
# Key functions:
# - fire_ray: wrapper function that fires a single ray through a
#   specified pixel by converting pixel coordinates to camera space.
# - fire_all_rays: iterates over all pixels and calls fire_ray.
# ─────────────────────────────────────────────────────────────

"""
    ImageTracer{T}

Handles ray generation from a camera through each pixel of an HDR image,
mapping pixel coordinates to camera space and storing ray results.
"""
struct ImageTracer{T<:AbstractFloat}
    image::HdrImage
    camera::Camera{T}
end


"""
    fire_ray(tracer::ImageTracer, col::Integer, row::Integer; u_pixel::AbstractFloat=0.5, v_pixel::AbstractFloat=0.5) -> Ray

Convert pixel coordinates `(col, row)` to screen coordinates `(u, v)` and generate a ray
from the camera through the specified point within that pixel.

# Arguments
- `tracer::ImageTracer`: The ImageTracer containing the camera and HDR image.
- `col::Integer`: The pixel column (starting from 1).
- `row::Integer`: The pixel row (starting from 1).
- `u_pixel::AbstractFloat=0.5`: Horizontal position in the pixel Horizontal offset inside the pixel (0 = left edge, 1 = right edge).
- `v_pixel::AbstractFloat=0.5`: Vertical position in the pixel Vertical offset inside the pixel (0 = top edge, 1 = bottom edge).

# Returns
- A `Ray` generated from the camera towards the specified point within the pixel.
"""
function fire_ray(
    tracer::ImageTracer,
    col::Integer,
    row::Integer;
    u_pixel::AbstractFloat = 0.5,
    v_pixel::AbstractFloat = 0.5,
)

    # Pixels indexed by (col, row), starting top-left:
    #
    #  (1,1)   (2,1)   ...   (width,1)
    #  +-----+ +-----+       +-----+
    #  |     | |     |       |     |
    #  +-----+ +-----+       +-----+
    #
    #  (1,2)   (2,2)   ...   (width,2)
    #  +-----+ +-----+       +-----+
    #  |     | |     |       |     |
    #  +-----+ +-----+       +-----+
    #
    #  ...     ...            ...
    #
    #  (1,height) ...       (width,height)

    # Each pixel has dimensions (1,1) in (u, v) coordinates,
    # hence the center is (0.5, 0.5)
    #
    #   (u=0, v=1) +--------+ (u=1, v=1)
    #              |        |
    #              |        |
    #   (u=0, v=0) +--------+ (u=1, v=0)

    #=

    u = (col - 1 + u_pixel) / (tracer.image.width)
    v = 1 - (row - 1 + v_pixel) / (tracer.image.height)

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


"Check that a number is a perfect square"
function is_square(n::Integer)
    # `isqrt(n)`: returns the largest integer m such that m*m <= n
    # Ex: isqrt(12) = 3
    return isqrt(n)^2 == n
end

"Custom exception for antialiasing-related errors"
struct AntialiasingError <: CustomException
    msg::String
end

"""
   fire_all_rays!(tracer::ImageTracer, func; samples_per_pixel::Integer=1, pcg::Union{PCG, Nothing}=nothing, progress_flag::Bool=true)

Renders the entire image by evaluating the rendering function `func` for each pixel.

For each pixel in the `HdrImage` inside `tracer`, this function fires rays through the pixel,
optionally performing antialiasing by sampling multiple subpixel locations (jittered samples),
and sets the pixel color to the computed result.

# Arguments
- `tracer::ImageTracer`: The object containing the camera and HDR image to be rendered.
- `func`: A function that takes a `Ray` and returns the computed color for that ray.
- `samples_per_pixel::Int=1`: Number of samples per pixel for antialiasing. Must be a perfect square (e.g., 1, 4, 9, 16).
- `pcg`: Optional random number generator for jittering sample positions.
- `progress_flag::Bool=true`: If `true`, displays a progress bar during rendering.

# Behavior
- If `samples_per_pixel == 1`, fires a single ray through the center of each pixel.
- If `samples_per_pixel > 1`, uses jittered subpixel sampling for antialiasing, averaging the results.
- Updates the pixels in-place on `tracer.image`.
"""
function fire_all_rays!(
    tracer::ImageTracer,
    func;
    samples_per_pixel::Integer = 1,
    pcg::Union{PCG,Nothing} = nothing,
    progress_flag::Bool = true,
)

    sqrt_samples = round(Int, sqrt(samples_per_pixel))
    if !is_square(samples_per_pixel)
        throw(
            AntialiasingError(
                "'samples_per_pixel' must be a perfect square (e.g., 1, 4, 9, 16, ...)",
            ),
        )
    end

    for row = 1:tracer.image.height
        for col = 1:tracer.image.width

            if samples_per_pixel == 1
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
                        ray = fire_ray(tracer, col, row; u_pixel = du, v_pixel = dv)
                        accumulated_color += func(ray)
                        averaged_color = accumulated_color * inv_samples
                        set_pixel!(tracer.image, col, row, averaged_color)
                    end
                end
            end
        end

    end
    progress_flag && simple_progress_bar(row, tracer.image.height)
end
