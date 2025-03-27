# COLOR METHODS

# Color-Color Sum
Base.:+(c1::ColorTypes.RGB{Float32}, c2::ColorTypes.RGB{Float32}) =
    ColorTypes.RGB{Float32}(c1.r + c2.r, c1.g + c2.g, c1.b + c2.b)

# Color-Scalar Product
Base.:*(scalar, c::ColorTypes.RGB{Float32}) =
    ColorTypes.RGB{Float32}(scalar * c.r, scalar * c.g, scalar * c.b)
Base.:*(c::ColorTypes.RGB{Float32}, scalar) = scalar * c # use the method defined previously

# Color-Color Product
Base.:*(c1::ColorTypes.RGB{Float32}, c2::ColorTypes.RGB{Float32}) =
    ColorTypes.RGB{Float32}(c1.r * c2.r, c1.g * c2.g, c1.b * c2.b)

# Color-Color ≈
Base.:≈(c1::ColorTypes.RGB{Float32}, c2::ColorTypes.RGB{Float32}) =
    ((c1.r ≈ c2.r) && (c1.g ≈ c2.g) && (c1.b ≈ c2.b))

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

# 