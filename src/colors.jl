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

# Color to String
function color_to_string(c::ColorTypes.RGB{Float32})
    str = "< r:" * string(c.r) * ", g:" * string(c.g) * ", b:" * string(c.b) * " >"
    return str
end


# HDR_IMAGE
#=
HdrImage(w=width, h=height)
HdrImage.pixels = [h, w]
=#
mutable struct HdrImage
    width::Integer
    height::Integer
    pixels::Matrix{ColorTypes.RGB{Float32}}
end

# Create HdrImage as a black image
function HdrImage(width::Integer, height::Integer) # HdrImage(column index, row index)
    pixels = fill(ColorTypes.RGB{Float32}(0.0, 0.0, 0.0), height, width)
    return HdrImage(width, height, pixels) # return the struct HdrImage
end

# # Create HdrImage from .pfm file
# function HdrImage(file::String)
# end

# function HdrImage(stream::IO)
# end

# Get pixel (R,G,B) from HdrImage
function get_pixel(img::HdrImage, w::Integer, h::Integer)
    return img.pixels[h, w]
end

# Set pixel (R,G,B) in HdrImage
function set_pixel!(img::HdrImage, w::Integer, h::Integer, new_color::ColorTypes.RGB{Float32})
    img.pixels[h, w] = new_color
end

# TONE MAPPING

"""
    luminosity(color::ColorTypes.RGB{Float32}; mean_type = :max_min, weights = [1,1,1])
Computes the luminosity of an RGB color using a specified method.\n
Valid options for methods are:
- `:max_min` Average of max and min channel values.
- `:arithmetic` Arithmetic mean of all channels.
- `:weighted` Weighted mean (requires `weights = [w_red, w_green, w_blue]`).
- `:distance` Distance from black (0,0,0).
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

"Compute the logarithmic average luminosity of an `HdrImage`."
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
function normalize_image(img::HdrImage; factor = 0.2, lumi = Nothing, delta = 1e-10, mean_type = :max_min, weights = [1, 1, 1])
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

"Correct bright spots."
function _clamp(x)
    x / (1+x)
end

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

# forse dovrei passare immagine nuova come stream!!
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
