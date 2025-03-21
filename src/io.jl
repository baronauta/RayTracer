# Input and Output

# Writing Color to stream
function Base.write(io::IO, color::ColorTypes.RGB{Float32}; endianness = my_endian)

    check_endianness(endianness)
    # Convert a floating-point number to 32-bit (4 bytes) integer for binary writing
    r = reinterpret(UInt32, color.r)
    g = reinterpret(UInt32, color.g)
    b = reinterpret(UInt32, color.b)

    need_to_convert = (
        (little_endian == true && endianness > 0) ||
        (little_endian == false && endianness < 0)
    )
    if need_to_convert == true
        if little_endian == true
            r = hton(r)
            g = hton(g)
            b = hton(b)
        elseif little_endian == false
            r = htol(r)
            g = htol(g)
            b = htol(b)
        end
    end

    write(io, r)
    write(io, g)
    write(io, b)
end

# Writing HdrImage to stream
function write(io::IO, image::HdrImage; endianness = my_endian)
    check_endianness(endianness)
    bytebuf = transcode(UInt8, "PF\n$(image.width) $(image.height)\n$endianness\n")
    write(io, bytebuf)
    for y = image.height:-1:1
        for x = 1:image.width
            write(io, get_pixel(image, x, y); endianness)
        end
    end
end

# Writing HdrImage to file
function write(filename::String, image::HdrImage; endianness = my_endian)
    check_extension(filename)
    check_endianness(endianness)
    open(filename, "w") do io
        write(io, image, endianness)
    end
end

# # Read HdrImage from file
# function read_pfm_image(filename::String)
#     io = open(filename, "r")
#     read_pfm_image(io)
# end

# Read HdrImage froom stream
function read_pfm_image(stream::IO)
    try
        # Read the magic, expected "PF"
        magic = readline(stream)
        if magic != "PF"
            throw(ArgumentError("invalid magic in PFM file"))
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
                        ArgumentError(
                            "number of bytes read exceeds the expected number of bytes",
                        ),
                    )
                end
            end
        end
        if bytes_read != expected_bytes
            throw(ArgumentError("expected $expected_bytes bytes, got $(length(raw_data))"))
        end
        return image
    catch e
        println("Error reading PFM file: ", e.msg)
    end
end

# Read image dimension
function _parse_img_size(str::String)
    parts = split(str, " ")
    if length(parts) != 2
        throw(ArgumentError("invalid size of the image in PFM file"))
    end
    width, height = parse.(Int, parts)
    if width <= 0 || height <= 0
        throw(ArgumentError("size of the image must be positive"))
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
        throw(ArgumentError("invalid endianness specification"))
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
