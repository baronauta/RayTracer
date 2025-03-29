# COLOR METHODS

# Color-Color Sum
Base.:+(c1::ColorTypes.RGB{Float32}, c2::ColorTypes.RGB{Float32}) =
    ColorTypes.RGB{Float32}(c1.r + c2.r, c1.g + c2.g, c1.b + c2.b)

# Color-Scalar Product
Base.:*(scalar::Real, c::ColorTypes.RGB{Float32}) =
    ColorTypes.RGB{Float32}(scalar * c.r, scalar * c.g, scalar * c.b)
Base.:*(c::ColorTypes.RGB{Float32}, scalar::Real) = scalar * c # use the method defined previously

# Color-Color Product
Base.:*(c1::ColorTypes.RGB{Float32}, c2::ColorTypes.RGB{Float32}) =
    ColorTypes.RGB{Float32}(c1.r * c2.r, c1.g * c2.g, c1.b * c2.b)

# Color-Color ≈
Base.:≈(c1::ColorTypes.RGB{Float32}, c2::ColorTypes.RGB{Float32}) =
    ((isapprox(c1.r, c2.r, rtol=1e-3, atol=1e-3)) && (isapprox(c1.g, c2.g, rtol=1e-3, atol=1e-3)) && (isapprox(c1.b, c2.b, rtol=1e-3, atol=1e-3)))

"""
    color_to_string(c::ColorTypes.RGB{Float32})

Print RGB components of a color, e.g. `< r:0.1, g:0.2, b:0.3 >`
"""
function color_to_string(c::ColorTypes.RGB{Float32})
    str = "< r:" * string(c.r) * ", g:" * string(c.g) * ", b:" * string(c.b) * " >"
    return str
end


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
    return HdrImage(width, height, pixels) # return the struct HdrImage
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
function set_pixel!(img::HdrImage, w::Integer, h::Integer, new_color::ColorTypes.RGB{Float32})
    img.pixels[h, w] = new_color
end

# TONE MAPPING

"""
    luminosity(color::ColorTypes.RGB{Float32}; mean_type = :max_min, weights = [1,1,1])

Computes the luminosity of an RGB color using a specified method.

# Valid options for methods
- `:max_min`: Average of max and min channel values.
- `:arithmetic`: Arithmetic mean of all channels.
- `:weighted`: Weighted mean (requires `weights = [w_red, w_green, w_blue]`).
- `:distance`: Distance from black (0,0,0).
"""
function luminosity(color::ColorTypes.RGB{Float32}; mean_type = :max_min, weights = [1,1,1])
    r, g, b = color.r, color.g, color.b
    if mean_type == :max_min
        return (max(r, g, b) + min(r, g, b)) / 2
    elseif mean_type == :arithmetic
        return (r + g + b) / 3
    elseif mean_type == :weighted
        return Float32((r*weights[1] + g*weights[2] + b*weights[3]) / sum(weights))
    elseif mean_type == :distance
        return (r^2 + g^2 + b^2)^(0.5)
    else
        throw(ToneMappingError(
            "Invalid mean_type: $mean_type. Expected one of the following:\n" *
            ":max_min\n" *
            ":arithmetic\n" *
            ":distance\n" *
            ":weighted (if used, pass weights = [wr, wg, wb], all 1 by default)"
        ))
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
function log_average(image::HdrImage; delta=1e-10, mean_type = :max_min, weights = [1,1,1])
    cumsum = 0
    for pixel in image.pixels
        cumsum += log10(luminosity(pixel; mean_type = mean_type, weights = weights)+delta)
    end
    # Logarithmic (base 10) average
    10^(cumsum/(image.width*image.height))
end

"""
    normalize_image(img::HdrImage; factor = 1.0, lumi = Nothing, delta = 1e-10, mean_type = :max_min, weights = [1, 1, 1])

Normalize the values of an RGB color using the average luinosity and the normalization factor (to be specified by the user).
"""
function normalize_image(img::HdrImage; factor = 1.0, lumi = Nothing, delta = 1e-10, mean_type = :max_min, weights = [1, 1, 1])
    if lumi == Nothing
        lumi = log_average(img; delta=delta, mean_type = mean_type, weights = weights)
    end
    a = factor / lumi
    for w in 1:img.width
        for h in 1:img.height
            c = get_pixel(img, w, h)
            r = c.r * a
            g = c.g * a
            b = c.b * a
            set_pixel!(img, w, h, ColorTypes.RGB{Float32}(r,g,b))
        end
    end
end

"""
    _clamp(x)

Clamp a brightness value `x` to reduce extreme brightness by mapping it to the range [0,1].
"""
function _clamp(x)
    x / (1+x)
end

"""
    clamp_image!(image::HdrImage)

Adjust the image by clamping the RGB components of each pixel, thereby reducing overly bright spots. The operation is performed in-place.
"""
function clamp_image!(image::HdrImage)
    for y in 1:image.height
        for x in 1:image.width
            r = _clamp(image.pixels[x,y].r)
            g = _clamp(image.pixels[x,y].g)
            b = _clamp(image.pixels[x,y].b)
            color = colorTypes.RGB{Float32}(r, g, b)
            set_pixel!(image, x, y, color)
        end
    end
    image
end

"""
    write_ldr_image(image::HdrImage, filename::String; gamma=1.0)

Convert an `HdrImage` to an 8-bit Low Dynamic Range (LDR) image with gamma correction and save it to a file.

# Arguments
- `image::HdrImage`: The HDR image to be converted.
- `filename::String`: The output file path.
- `gamma`: The gamma correction factor (default: `1.0`).

The function applies gamma correction and scales pixel values to the 0-255 range before saving.
"""
function write_ldr_image(image::HdrImage, filename::String; gamma=1.0)
    for y in 1:image.height
        for x in 1:image.width
            r = Int(255*image.pixels[x,y].r^(1/gamma))
            g = Int(255*image.pixels[x,y].g^(1/gamma))
            b = Int(255*image.pixels[x,y].b^(1/gamma))
            color = colorTypes.RGB{Float32}(r, g, b)
            set_pixel!(image, x, y, color)
        end
    end
    Images.save(filename, image)
end
