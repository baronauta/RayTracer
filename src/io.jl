# Input/Output utilities

import Base: write

# ─────────────────────────────────────────────────────────────
# Endianness functions
# ─────────────────────────────────────────────────────────────

# setting my_endian = to host endian
my_endian = 0.0
if little_endian
    my_endian = -1.0
else
    my_endian = 1.0
end

"Check if the endianness format is valid and not zero"
function check_endianness(value)
    if typeof(value) <: Real
        if value == 0
            throw(
                WrongPFMformat(
                    "endianness can't be 0, choose a number >0 for big endian or <0 for little endian",
                ),
            )
        end
    else
        throw(WrongPFMformat("endianness must be an Integer or Float"))
    end
end


# ─────────────────────────────────────────────────────────────
# Methods for writing Color and images to stream or file
# ─────────────────────────────────────────────────────────────

"Check if the PFM file format is valid"
function check_extension(s)
    if !endswith(s, ".PFM")
        throw(
            WrongPFMformat("the file must be a PFM file. Please insert a valid file name"),
        )
    end
end

"""
    write(io::IO, color::ColorTypes.RGB{Float32}; endianness = my_endian)

Writes an RGB Color to a stream in the specified endianness.

# Arguments:
- `io::IO`: The output stream to write to;
- `color::ColorTypes.RGB{Float32}`: The color to write;
- `endianness`: The byte order for writing (default: `my_endian`).
"""
function Base.write(io::IO, color::ColorTypes.RGB{Float32}; endianness = my_endian)

    check_endianness(endianness)

    # Convert a floating-point number to 32-bit (4 bytes) integer for binary writing
    r = reinterpret(UInt32, color.r)
    g = reinterpret(UInt32, color.g)
    b = reinterpret(UInt32, color.b)

    # change endianness according to choosen one
    if endianness > 0
        r = hton(r)
        g = hton(g)
        b = hton(b)
    elseif endianness < 0
        r = htol(r)
        g = htol(g)
        b = htol(b)
    end
    # writing colors to stream
    write(io, r)
    write(io, g)
    write(io, b)
end

"""
    write(io::IO, image::HdrImage; endianness = my_endian)

Writes a PFM image to a stream in the specified endianness.

# Arguments:
- `io::IO`: The output stream to write to;
- `image::HdrImage`: The HDR image to write;
- `endianness`: The byte order for writing (default: `my_endian`).
"""
function Base.write(io::IO, image::HdrImage; endianness = my_endian)
    check_endianness(endianness)
    bytebuf = transcode(UInt8, "PF\n$(image.width) $(image.height)\n$endianness\n")
    write(io, bytebuf)
    for y = image.height:-1:1
        for x = 1:image.width
            write(io, get_pixel(image, x, y); endianness)
        end
    end
end

"""
    write(filename::String, image::HdrImage; endianness = my_endian)

Writes an HDR image to a file in the specified endianness.

# Arguments:
- `filename::String`: The name of the file to write to;
- `image::HdrImage`: The HDR image to write;
- `endianness`: The byte order for writing (default: `my_endian`).
"""
function Base.write(filename::String, image::HdrImage; endianness = my_endian)
    check_extension(filename)
    open(filename, "w") do io
        write(io, image, endianness)
    end
end

"""
    write_ldr_image(image::HdrImage, filename::String; gamma=1.0)

Convert an `HdrImage` to an 8-bit Low Dynamic Range (LDR) image with gamma correction and save it to a file.

# Arguments
- `image::HdrImage`: The HDR image to be converted.
- `filename::String`: The output file path.
- `gamma`: The gamma correction factor (default: `1.0`).

The function applies gamma correction before saving.
"""
function write_ldr_image(image::HdrImage, filename::String; gamma = 1.0)
    for h = 1:image.height
        for w = 1:image.width
            pix = get_pixel(image, w, h)
            color = ColorTypes.RGB{Float32}(
                pix.r^(1 / gamma),
                pix.g^(1 / gamma),
                pix.b^(1 / gamma),
            )
            set_pixel!(image, w, h, color)
        end
    end
    # Using save function from Images packages
    Images.save(filename, image.pixels)
end

# ─────────────────────────────────────────────────────────────
# Reading PFM Images functions
# ─────────────────────────────────────────────────────────────

"""
    read_pfm_image(filename::String)
Read a PFM Image from a file
# Returns
- The corresponding HdrImage.
"""
function read_pfm_image(filename::String)
    open(filename, "r") do io
        return read_pfm_image(io)
    end
end

"""
    read_pfm_image(stream::IO)
Read a PFM Image from a stream
# Returns
- The corresponding HdrImage.
"""
function read_pfm_image(stream::IO)
    try
        # Read the magic, expected "PF"
        magic = readline(stream)
        if magic != "PF"
            throw(WrongPFMformat("invalid magic in PFM file"))
        end
        # Read the image size, expected "<width> <height>"
        width, height = _parse_img_size(readline(stream))
        # Read the endianness, expected "+1.0" or "-1.0"
        endianness = _parse_endianness(readline(stream))
        # Create HdrImage
        image = HdrImage(width, height)
        # Calculate expected data size (width * height * 3 for RGB)
        expected_float = width * height * 3
        expected_bytes = expected_float * sizeof(Float32)
        # Initialise byte counter
        bytes_read = 0
        # Read and process the data
        # PFM stores from bottom-left
        for y = image.height:-1:1
            for x = 1:image.width
                if bytes_read < expected_bytes
                    # Read the three floats for the pixel
                    (r, g, b) = [_read_float(stream, endianness) for _ = 1:3]
                    bytes_read += 3 * sizeof(Float32)
                    color = ColorTypes.RGB{Float32}(r, g, b)
                    # Set pixel in HdrImage
                    set_pixel!(image, x, y, color)
                else
                    throw(
                        WrongPFMformat(
                            "number of bytes read exceeds the expected number of bytes",
                        ),
                    )
                end
            end
        end
        if bytes_read != expected_bytes
            throw(WrongPFMformat("expected $expected_bytes bytes, got $(length(raw_data))"))
        end
        return image
    catch e
        println("$(typeof(e)): $(e.msg)")
    end
end

# Read image dimension
function _parse_img_size(str::String)
    parts = split(str, " ")
    if length(parts) != 2
        throw(WrongPFMformat("invalid size of the image in PFM file"))
    end
    width, height = parse.(Int, parts)
    if width <= 0 || height <= 0
        throw(WrongPFMformat("size of the image must be positive"))
    end
    return width, height
end

# Parse endianness
function _parse_endianness(str::String)
    value = parse(Float32, str)
    if value > 0
        return Float32(1.0)
    elseif value < 0
        return Float32(-1.0)
    else
        throw(WrongPFMformat("invalid endianness specification"))
    end
end

# Read 32-bit floating point number, that is read 4 bytes
# n: big-endian
# l: little-endian
# h: host endianness
function _read_float(stream::IO, endianness::Float32)
    x = read(stream, UInt32)
    is_big_endian = endianness == 1.0
    x = (is_big_endian == true) ? ntoh(x) : ltoh(x)
    reinterpret(Float32, x)
end
