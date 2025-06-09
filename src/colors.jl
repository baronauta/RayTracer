
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


"Wrapper function to ColorTypes.RGB{Float32}."
function RGB(r, g, b)
    ColorTypes.RGB{Float32}(r, g, b)
end

"Show an RGB color"
function Base.show(io::IO, c::ColorTypes.RGB)
    print(io, "ColorTypes.RGB(r=$(c.r), g=$(c.g), b=$(c.b))")
end

function Base.show(io::IO, ::MIME"text/plain", c::ColorTypes.RGB)
    show(io, c)
end

const WHITE = RGB(1.0, 1.0, 1.0)
const BLACK = RGB(0.0, 0.0, 0.0)
const GRAY = RGB(0.5, 0.5, 0.5)
const RED = RGB(1.0, 0.0, 0.0)
const GREEN = RGB(0.0, 1.0, 0.0)
const BLUE = RGB(0.0, 0.0, 1.0)

"Add two RGB colors, returning a new RGB color."
function +(x::ColorTypes.RGB, y::ColorTypes.RGB)
    RGB(x.r + y.r, x.g + y.g, x.b + y.b)
end

"Multiply a RGB color by a scalar, returning a new RGB color."
function *(s::Real, c::ColorTypes.RGB)
    RGB(s * c.r, s * c.g, s * c.b)
end

"Component-wise product between two RGB colors, returning a new RGB color."
function *(x::ColorTypes.RGB, y::ColorTypes.RGB)
    RGB(x.r * y.r, x.g * y.g, x.b * y.b)
end

"Check if two RGB colors are approximately equal."
function ≈(x::ColorTypes.RGB, y::ColorTypes.RGB)
    isapprox(x.r, y.r, rtol = 1e-3, atol = 1e-3) &&
        isapprox(x.g, y.g, rtol = 1e-3, atol = 1e-3) &&
        isapprox(x.b, y.b, rtol = 1e-3, atol = 1e-3)
end

# ─────────────────────────────────────────────────────────────
# Defining HdrImage and their functions
# ─────────────────────────────────────────────────────────────

"""
    HdrImage

A mutable struct representing a High Dynamic Range (HDR) image.

# Fields
- `width::Integer`: The width of the image.
- `height::Integer`: The height of the image.
- `pixels::Matrix{ColorTypes.RGB{Float32}}`: A 2D matrix of pixels, where each pixel is an RGB color with `Float32` components.
"""
mutable struct HdrImage
    width::Integer
    height::Integer
    pixels::Matrix{ColorTypes.RGB{Float32}}
end

"""
    HdrImage(width::Integer, height::Integer)

Create a new `HdrImage` with the specified dimensions. 
All pixels are initially set to black, i.e. `RGB{Float32}(0.0, 0.0, 0.0)`.
"""
function HdrImage(width::Integer, height::Integer) # HdrImage(column index, row index)
    pixels = fill(ColorTypes.RGB{Float32}(0.0, 0.0, 0.0), height, width)
    return HdrImage(width, height, pixels)
end

"""
    get_pixel(img::HdrImage, w::Integer, h::Integer)

Retrieve the pixel (R, G, B) at column `w` and row `h` from the HDR image.
"""
function get_pixel(img::HdrImage, w::Integer, h::Integer)
    return img.pixels[h, w]
end

"""
    set_pixel!(img::HdrImage, w::Integer, h::Integer, new_color::ColorTypes.RGB{Float32})

Set the pixel at column `w` and row `h` in the HDR image to `new_color`.
"""
function set_pixel!(
    img::HdrImage,
    w::Integer,
    h::Integer,
    new_color::ColorTypes.RGB{Float32},
)
    img.pixels[h, w] = new_color
end

# ─────────────────────────────────────────────────────────────
# Tone Mapping
# ─────────────────────────────────────────────────────────────

"""
    luminosity(color::ColorTypes.RGB{Float32}; mean_type = :max_min, weights = [1,1,1])

Computes the luminosity of an RGB color using a specified method.

# Valid options for methods
- `:max_min`: Average of max and min channel values.
- `:arithmetic`: Arithmetic mean of all channels.
- `:weighted`: Weighted mean (requires `weights = [w_red, w_green, w_blue]`).
- `:distance`: Distance from black (0,0,0).
"""
function luminosity(
    color::ColorTypes.RGB{Float32};
    mean_type = :max_min,
    weights = [1, 1, 1],
)
    r, g, b = color.r, color.g, color.b
    if mean_type == :max_min
        return (max(r, g, b) + min(r, g, b)) / 2
    elseif mean_type == :arithmetic
        return (r + g + b) / 3
    elseif mean_type == :weighted
        return Float32((r * weights[1] + g * weights[2] + b * weights[3]) / sum(weights))
    elseif mean_type == :distance
        return (r^2 + g^2 + b^2)^(0.5)
    else
        throw(
            ToneMappingError(
                "invalid mean_type: $mean_type. Expected one of the following:\n" *
                ":max_min\n" *
                ":arithmetic\n" *
                ":distance\n" *
                ":weighted (if used, pass weights = [wr, wg, wb], all 1 by default)",
            ),
        )
    end
end

"""
    log_average(image::HdrImage; delta=1e-10, mean_type=:max_min, weights=[1,1,1])

Compute the logarithmic average luminosity of an `HdrImage`.

# Arguments
- `image::HdrImage`: The HDR image.
- `delta`: A small constant added to avoid log of zero (default: 1e-10).
- `mean_type`: The method for computing luminosity (default: `:max_min`).
- `weights`: Weights for the luminosity computation (default: `[1,1,1]`).

# Returns
- The logarithmic (base 10) average luminosity of the image.
"""
function log_average(
    image::HdrImage;
    delta = 1e-10,
    mean_type = :max_min,
    weights = [1, 1, 1],
)
    cumsum = 0
    for pixel in image.pixels
        cumsum += log10(luminosity(pixel; mean_type = mean_type, weights = weights) + delta)
    end
    # Logarithmic (base 10) average
    return 10^(cumsum / (image.width * image.height))
end

"""
    normalize_image(img::HdrImage; factor = 1.0, lumi = nothing, delta = 1e-10, mean_type = :max_min, weights = [1, 1, 1])

Normalize the values of an RGB color using the average luminosity and the normalization factor (to be specified by the user).
"""
function normalize_image!(
    img::HdrImage;
    factor = 1.0,
    lumi = nothing,
    delta = 1e-10,
    mean_type = :max_min,
    weights = [1, 1, 1],
)
    lumi = something(
        lumi,
        log_average(img; delta = delta, mean_type = mean_type, weights = weights),
    )
    a = factor / lumi
    for w = 1:img.width
        for h = 1:img.height
            c = get_pixel(img, w, h)
            c *= a
            set_pixel!(img, w, h, c)
        end
    end
end

"""
    _clamp(x)

Clamp a brightness value `x` to reduce extreme brightness by mapping it to the range [0,1].
"""
function _clamp(x)
    x / (1 + x)
end

"""
    clamp_image!(image::HdrImage)

Adjust the image by clamping the RGB components of each pixel, thereby reducing overly bright spots. The operation is performed in-place.
"""
function clamp_image!(image::HdrImage)
    for h = 1:image.height
        for w = 1:image.width
            r = _clamp(image.pixels[h, w].r)
            g = _clamp(image.pixels[h, w].g)
            b = _clamp(image.pixels[h, w].b)
            color = ColorTypes.RGB{Float32}(r, g, b)
            set_pixel!(image, w, h, color)
        end
    end
end
