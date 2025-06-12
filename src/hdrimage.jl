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

"""
    HdrImage

Matrix of colors where R,G,B components are floating-point numbers.

# Fields
- `width::Integer`: image width.
- `height::Integer`: image heigh
- `pixels::Matrix{ColorTypes.RGB{Float32}}`: 2D matrix of RGB pixels with `Float32` components.
"""
mutable struct HdrImage
    width::Integer
    height::Integer
    pixels::Matrix{ColorTypes.RGB{Float32}}
end

"""
    HdrImage(width::Integer, height::Integer)

Constructs a new `HdrImage` of the given size with all pixels initialized 
to black (`RGB{Float32}(0, 0, 0)`).
"""
function HdrImage(width::Integer, height::Integer)
    pixels = fill(ColorTypes.RGB{Float32}(0.0, 0.0, 0.0), height, width)
    return HdrImage(width, height, pixels)
end

"""
Return the RGB pixel at column `w`, row `h` of the HDR image.
"""
function get_pixel(img::HdrImage, w::Integer, h::Integer)
    # Images are defined as width × height,
    # matrix are defined rows × columns.
    return img.pixels[h, w]
end

"""
Set the pixel at column `w`, row `h` to `new_color`.
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
#
# HdrImage can't be displayed. Convert to Low-Dynamic Range (LDR)
# images that encodes R,G,B components as ..... This conversion
# is named Tone Mapping.
# ─────────────────────────────────────────────────────────────

"Custom exception for errors encountered during tone mapping"
struct ToneMappingError <: CustomException
    msg::String
end

"""
Computes the luminosity of an RGB color.

# Arguments
- `mean_type`: method to compute luminosity (`:max_min`, `:arithmetic`, `:weighted`, or `:distance`).
- `weights`: Channel weights used only if `mean_type == :weighted` (default: `[1, 1, 1]`).

# Methods
- `:max_min`: Average of the max and min RGB values.
- `:arithmetic`: Mean of all channels.
- `:weighted`: Weighted average using `weights`.
- `:distance`: Euclidean distance from black (0, 0, 0).
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
    normalize_image(img::HdrImage; factor = 0.2, lumi = nothing, delta = 1e-10, mean_type = :max_min, weights = [1, 1, 1])

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
