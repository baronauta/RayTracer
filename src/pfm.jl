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


"Incorrect PFM format"
struct WrongPFMformat <: CustomException
    msg::String
end

"Validate endianness value: it must be a non zero number"
function _check_endianness(value)
    # Check if the value is a number (either integer or float) and non-zero
    if !(typeof(value) <: Real) || value == 0
        throw(WrongPFMformat("endianness must be a non-zero number"))
    end
end

"""
Write a ColorTypes.RGB color to stream in binary, using specified endianness (`>0` big, `<0` little).
Default endianness to `HOST_ENDIANNESS`, which matches the host machine's byte order.
"""
function write_color(io::IO, color::ColorTypes.RGB; endianness = HOST_ENDIANNESS)
    _check_endianness(endianness)

    # Convert a floating-point number to 32-bit (4 bytes) integer for binary writing
    r = reinterpret(UInt32, color.r)
    g = reinterpret(UInt32, color.g)
    b = reinterpret(UInt32, color.b)

    # Change endianness according to the chosen one, default `HOST_ENDIANNESS`
    if endianness > 0
        r = hton(r)
        g = hton(g)
        b = hton(b)

    elseif endianness < 0
        r = htol(r)
        g = htol(g)
        b = htol(b)
    end

    write(io, r)
    write(io, g)
    write(io, b)
end

"""
    write(io::IO, image::HdrImage; endianness = HOST_ENDIANNESS)

Write an `HdrImage` to the given output stream in PFM format. 

# Arguments
- `io::IO`: output stream to write binary color data to.
- `image::HdrImage`: HDR image to be written.
- `endianness`: `>0` big, `<0` little (defaults to `HOST_ENDIANNESS`, which matches the host machine's byte order.)
"""
function write(io::IO, image::HdrImage; endianness = HOST_ENDIANNESS)
    _check_endianness(endianness)
    bytebuf = transcode(UInt8, "PF\n$(image.width) $(image.height)\n$endianness\n")
    write(io, bytebuf)
    # Scanline order
    # - from left to right
    # - from bottom to top (note reversed order for `y`)
    for y = image.height:-1:1
        for x = 1:image.width
            write_color(io, get_pixel(image, x, y); endianness)
        end
    end
end

"""
    write(filename::String, image::HdrImage; endianness = HOST_ENDIANNESS)

Write a HDR image into a file with PFM format. 

# Arguments:
- `filename::String`: name of the output file (must have .pfm extension).
- `image::HdrImage`: HDR image to be written.
- `endianness`: `>0` big, `<0` little (defaults to `HOST_ENDIANNESS`, which matches the host machine's byte order.)
"""
function write(filename::String, image::HdrImage; endianness = HOST_ENDIANNESS)
    try 
        expected_extension(filename, [".pfm"])
        open(filename, "w") do io
            write(io, image; endianness)
        end
    catch e
        if isa(e, CustomException)
            println(e)
        else
            rethrow()
        end
    end
end


"Parse image dimension from a PFM file: expected `<width> <height>`"
function _parse_img_size(str::String)
    parts = split(str, " ")
    if length(parts) != 2
        throw(WrongPFMformat("expected two integers for image size, got $(length(parts))"))
    end
    width, height = parse.(Int, parts)
    if width <= 0 || height <= 0
        throw(WrongPFMformat("image dimensions must be positive, got width=$width, height=$height"))
    end
    return width, height
end

"Parse endianness from a PFM file"
function _parse_endianness(str::String)
    value = parse(Float32, str)
    _check_endianness(value)
    value > 0 ? Float32(1.0) : Float32(-1.0)
end

"Read 32-bit floating point number, i.e. read 4 bytes"
function _read_float(stream::IO, endianness::Real)
    _check_endianness(endianness)
    x = read(stream, UInt32)
    # n (big-endian), l (little-endian), h (host endianness)
    # - ntoh(x) i.e. from hostendiannes to big-endian
    x = endianness == 1.0 ? ntoh(x) : ltoh(x)
    return reinterpret(Float32, x)
end

"""
    read_pfm_image(stream::IO)
    
Read a PFM image from a stream and return an `HdrImage` with 32-bit float RGB values.
"""
function read_pfm_image(stream::IO)
    # Read the magic, expected "PF"
    magic = readline(stream)
    if magic != "PF"
        throw(WrongPFMformat("expected magic string \"PF\", but found \"$magic\""))
    end
    # Read the image size, expected "<width> <height>"
    width, height = _parse_img_size(readline(stream))
    # Read the endianness, expected "+1.0" or "-1.0"
    endianness = _parse_endianness(readline(stream))

    # Create HdrImage
    image = HdrImage(width, height)
    # Expected data size
    expected_floats = width * height * 3    # 3 because RGB
    expected_bytes = expected_floats * sizeof(Float32)
    bytes_read = 0  # initialise counter

    # PFM stores data from bottom-left
    for y = image.height:-1:1
        for x = 1:image.width
            if bytes_read + 3 * sizeof(Float32) > expected_bytes
                throw(WrongPFMformat("read more bytes than expected"))
            end
            r, g, b = (_read_float(stream, endianness) for _ in 1:3)
            bytes_read += 3 * sizeof(Float32)
            set_pixel!(image, x, y, RGB(r, g, b))
        end
    end
    if bytes_read != expected_bytes
        throw(WrongPFMformat("expected $expected_bytes bytes, got $(bytes_read)"))
    end
    return image
end

"""
    read_pfm_image(filename::String)

Read a PFM image from a stream and return an `HdrImage` with 32-bit float RGB values.
"""
function read_pfm_image(filename::String)
    try
        open(filename, "r") do io
            return read_pfm_image(io)
        end
    catch e
        if isa(e, CustomException)
            println(e)
        else
            rethrow()
        end
    end
end

