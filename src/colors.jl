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
mutable struct HdrImage
    width::Int
    height::Int
    pixels::Matrix{ColorTypes.RGB{Float32}}
end

# Create HdrImage as a black image
function HdrImage(width::Int, height::Int) # HdrImage(column index, row index)
    pixels = fill(ColorTypes.RGB{Float32}(0.0, 0.0, 0.0), height, width)
    return HdrImage(width, height, pixels) # return the struct HdrImage
end

# # Create HdrImage from .pfm file
# function HdrImage(file::String)
# end

# function HdrImage(stream::IO)
# end

# Get pixel (R,G,B) from HdrImage
function get_pixel(img::HdrImage, x::Int, y::Int)
    return img.pixels[y, x]
end

# Set pixel (R,G,B) in HdrImage
function set_pixel!(img::HdrImage, x::Int, y::Int, new_color::ColorTypes.RGB{Float32})
    img.pixels[y, x] = new_color
end

"Compute the logarithmic average luminosity of an `HdrImage`."
function log_average(image::HdrImage; delta=1e.10)
    cumsum = 0
    for pixel in image.pixels
        cumsum += log10(luminosity(pixel)+delta)
    end
    # Logarithmic (base 10) average
    10^(cumsum/size(HdrImage.pixels))
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
