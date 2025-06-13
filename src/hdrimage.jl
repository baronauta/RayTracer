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
- `height::Integer`: image height
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
# HdrImage are not suitable to be displayed: it stores pixels that
# span the whole tonal range of real-world scenes. 
# Convert to Low-Dynamic Range (LDR) images that are images where 
# the values of pixels don't exceed a maximum value, e.g. 255 or 1. 
# This conversion is named Tone Mapping.
#
# Algorithm
#   1. Establish an average value for the luminosity measured at
#      each pixel of the image,
#   2. Normalize the color of each pixel to this average value,
#   3. Apply a correction to the brightest spots.
#
# ─────────────────────────────────────────────────────────────

"Custom exception for errors encountered during tone mapping"
struct ToneMappingError <: CustomException
    msg::String
end

"""
Computes the luminosity of a RGB color.

# Arguments
- `mean_type`: method to compute luminosity (`:max_min`, `:arithmetic`, `:weighted`, or `:distance`).
- `weights`: vector of three components, used only if `mean_type == :weighted`.

# Methods
- `:max_min`: Average of the max and min RGB values.
- `:arithmetic`: Mean of all channels.
- `:weighted`: Weighted average using `weights`.
- `:distance`: Euclidean distance from black (0, 0, 0).
"""
function luminosity(
    color::ColorTypes.RGB{Float32};
    mean_type = :max_min,
    weights::Union{Nothing, AbstractVector{<:Real}} = nothing,
)
    r, g, b = color.r, color.g, color.b

    if mean_type == :max_min
        return (max(r, g, b) + min(r, g, b)) / 2

    elseif mean_type == :arithmetic
        return (r + g + b) / 3

    elseif mean_type == :weighted
        if isnothing(weights)
            throw(ToneMappingError("provide weights, it must be a vector of length 3"))
        elseif !isa(weights, AbstractVector) || length(weights) != 3
            throw(ToneMappingError("\"weights\" must be a vector of length 3"))
        elseif any(<(0), weights)
            throw(ToneMappingError("All elements in \"weights\" must be positive numbers"))
        else
            return Float32((r * weights[1] + g * weights[2] + b * weights[3]) / sum(weights))
        end

    elseif mean_type == :distance
        return (r^2 + g^2 + b^2)^(0.5)

    else
        throw(
            ToneMappingError(
                "expected \"mean_type\" to be one of {:max_min, :arithmetic, :distance, :weighted}, found \"$mean_type\""
            )
        )
    end
end

"""
Compute logarithmic average for the luminosity of the pixels in a HDR image.

# Arguments
- `image::HdrImage`: HDR image.
- `delta`: small constant added to avoid log of zero (default: 1e-10).
- `mean_type`: the method for computing luminosity (default: `:max_min`).
- `weights`: weights rquired to compute luminosity in the case of `mean_type=:weighted`.
"""
function log_average(
    image::HdrImage;
    delta = 1e-10,
    mean_type = :max_min,
    weights::Union{Nothing, AbstractVector{<:Real}} = nothing,
)
    cumsum = 0
    for pixel in image.pixels
        cumsum += log10(luminosity(pixel; mean_type = mean_type, weights = weights) + delta)
    end
    return 10^(cumsum / (image.width * image.height))
end

"""
Normalise the pixel values of an HDR image by scaling colors based on the average luminosity 
and a user-defined normalization factor.

# Arguments
- `image::HdrImage`: HDR image to be normalized
- `lumi`: precomputed average luminosity; if `nothing`, it is computed from the image (default: `nothing`).
- `a`: scaling factor applied after normalization (default: `1.0`).
- `mean_type`: Method for computing pixel luminosity (default: `:max_min`).
- `weights`: Vector of weights for `:weighted` luminosity method (default: `nothing`).
"""
function normalize_image!(
    img::HdrImage;
    lumi::Union{Nothing, AbstractFloat} = nothing,
    mean_type = :max_min,
    weights::Union{Nothing, AbstractVector{<:Real}} = nothing,
    a::Real = 1.0,
)
    if isnothing(lumi)
        lumi = log_average(img; mean_type = mean_type, weights = weights)
    end

    # Update the R, G, B values of the HDR image through
    # the transformation: Rᵢ → a ⋅ Rᵢ / <l>.
    scale = a / lumi
    for w = 1:img.width
        for h = 1:img.height
            c = get_pixel(img, w, h)
            set_pixel!(img, w, h, scale*c)
        end
    end
end

function _clamp(x)
    return x / (1 + x)
end

"Handle bright spots applying the transformation Rᵢ → Rᵢ / ( 1 + Rᵢ )"
function clamp_image!(image::HdrImage)
    for h = 1:image.height
        for w = 1:image.width
            r = _clamp(image.pixels[h, w].r)
            g = _clamp(image.pixels[h, w].g)
            b = _clamp(image.pixels[h, w].b)
            color = RGB(r, g, b)
            set_pixel!(image, w, h, color)
        end
    end
end

"""
Perform tone mapping on a `HdrImage`.

# Arguments
- `image::HdrImage`:  HDR image to convert.
- `mean_type::String`: Method for computing pixel luminosity (default: `max_min`).
- `weights`: Vector of weights for `weighted` luminosity method (default: `nothing`).
- `a`: scaling factor applied after normalization (default: `1.0`).
"""
function tonemapping!(
    img::HdrImage;
    mean_type = "max_min",
    weights::Union{Nothing, AbstractVector{<:Real}} = nothing,
    a = 1.0,
)
    # make mean_type a Symbol
    symbol_mean_type = Symbol(mean_type)
    # Validate `a`
    if !isa(a, Real)
        throw(ToneMappingError("expected a real number for \"a\", got $(typeof(a))"))
    elseif !(a>0)
        throw(ToneMappingError("expected a positive number for \"a\", got $(a)"))
    end

    normalize_image!(
        img; 
        mean_type = symbol_mean_type,
        weights = weights,
        a = a,
    )
    clamp_image!(img)
end


# ─────────────────────────────────────────────────────────────
# Saving LDR Images
#
# To save an image in an LDR format, we use `Images.save(filename, img)`.
# The output format is inferred from the filename extension.
# The image `img` must be a matrix of RGB pixels with values 
# normalized in [0, 1].
# ─────────────────────────────────────────────────────────────

"""
    write_ldr_image(filename::String, image::HdrImage; gamma=1.0)

Create a copy of `HdrImage`, perform gamma correction and save it to a file.

# Arguments
- `filename::String`: The path where the LDR image will be saved (e.g., `"output.png"`).
- `image::HdrImage`:  HDR image to convert.
- `gamma`: gamma correction factor (default: `1.0`).
"""
function write_ldr_image(
    filename::String, 
    img::HdrImage;
    gamma = 1.0,
    )

    # Validate `gamma`
    if !isa(gamma, Real)
        throw(ToneMappingError("expected a real number for \"gamma\", got $(typeof(gamma))"))
    elseif !(gamma>0)
        throw(ToneMappingError("expected a positive number for \"gamma\", got $(gamma)"))
    end

    # Gamma correction
    img_out = deepcopy(img)
    for h in 1:img_out.height, w in 1:img_out.width
        pix = get_pixel(img_out, w, h)
        color = RGB(
            pix.r^(1 / gamma),
            pix.g^(1 / gamma),
            pix.b^(1 / gamma)
        )
        set_pixel!(img_out, w, h, color)
    end

    # Values must be expressed in the range [0, 1]
    Images.save(filename, img_out.pixels)
end