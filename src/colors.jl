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
HdrImage(x=width, y=height)
HdrImage.pixels = [y, x]
=#

# Struct Definition
mutable struct HdrImage
    width::Int
    height::Int
    pixels::Matrix{ColorTypes.RGB{Float32}}
end
# Create the struct HdrImage
function HdrImage(width::Int, height::Int) # HdrImage(column index, row index)
    pixels = fill(ColorTypes.RGB{Float32}(0.0, 0.0, 0.0), height, width)
    return HdrImage(width, height, pixels) # return the struct HdrImage
end

# Read parameters
function get_pixel(img::HdrImage, x::Int, y::Int)
    return img.pixels[y, x]
end

# Write parameters
function set_pixel!(img::HdrImage, x::Int, y::Int, new_color::ColorTypes.RGB{Float32})
    img.pixels[y, x] = new_color
end
