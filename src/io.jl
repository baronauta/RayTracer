
#_______________________________________________________________________________________
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
#
#_______________________________________________________________________________________


# ─────────────────────────────────────────────────────────────
# About HDR and LDR images:
# - write and read methods.
# ─────────────────────────────────────────────────────────────

"Check that given endianness is valid: it must be a non zero number."
function check_endianness(value)
    # Check if the value is a number (either integer or float) and non-zero
    if !(typeof(value) <: Real) || value == 0
        throw(WrongPFMformat("endianness must be a non-zero number."))
    end
end

"Check if the PFM file format is valid."
function check_pfm_extension(s)
    # Check if the file extension is .pfm (case-insensitive)
    if !endswith(lowercase(s), ".pfm")
        throw(
            WrongPFMformat(
                "the file must be a PFM file. Please provide a valid file name.",
            ),
        )
    end
end

"""
    write_color(io::IO, color::ColorTypes.RGB{Float32}; endianness = HOST_ENDIANNESS)

Write an RGB color (`Float32` precision) to the given output stream in binary format, using the specified byte order.

# Arguments
- `io::IO`: The output stream to write binary color data to.
- `color::ColorTypes.RGB{Float32}`: The color values to be written.
- `endianness`: A non-zero number indicating the byte order:
    - `> 0`: Big endian
    - `< 0`: Little endian  
    (Defaults to `HOST_ENDIANNESS`, which matches the host machine's byte order.)
"""
function write_color(io::IO, color::ColorTypes.RGB{Float32}; endianness = HOST_ENDIANNESS)
    check_endianness(endianness)
    # Convert a floating-point number to 32-bit (4 bytes) integer for binary writing
    r = reinterpret(UInt32, color.r)
    g = reinterpret(UInt32, color.g)
    b = reinterpret(UInt32, color.b)
    # Change endianness according to th chosen one, default `HOST_ENDIANNESS`
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
- `io::IO`: The output stream to write binary color data to.
- `image::HdrImage`: The HDR image to be written.
- `endianness`: A non-zero number indicating the byte order:
    - `> 0`: Big endian
    - `< 0`: Little endian  
    (Defaults to `HOST_ENDIANNESS`, which matches the host machine's byte order.)
"""
function write(io::IO, image::HdrImage; endianness = HOST_ENDIANNESS)
    check_endianness(endianness)
    bytebuf = transcode(UInt8, "PF\n$(image.width) $(image.height)\n$endianness\n")
    write(io, bytebuf)
    # Scanline order:
    # from left to right and from bottom to top (note reversed order for `y`)
    for y = image.height:-1:1
        for x = 1:image.width
            write_color(io, get_pixel(image, x, y); endianness)
        end
    end
end

"""
    write(filename::String, image::HdrImage; endianness = HOST_ENDIANNESS)

Write an `HdrImage` to the given filename in PFM format. 

# Arguments:
- `filename::String`: The name of the file to write to.
- `image::HdrImage`: The HDR image to be written.
- `endianness`: A non-zero number indicating the byte order:
    - `> 0`: Big endian
    - `< 0`: Little endian  
    (Defaults to `HOST_ENDIANNESS`, which matches the host machine's byte order.)
"""
function write(filename::String, image::HdrImage; endianness = HOST_ENDIANNESS)
    check_pfm_extension(filename)
    open(filename, "w") do io
        write(io, image; endianness)
    end
end

"""
    write_ldr_image(filename::String, image::HdrImage; gamma=1.0)

Convert an `HdrImage` to an 8-bit Low Dynamic Range (LDR) image using gamma correction, and save it to a file.

# Arguments
- `filename::String`: The path where the LDR image will be saved (e.g., `"output.png"`).
- `image::HdrImage`: The input HDR image to convert.
- `gamma`: Gamma correction factor (default: `1.0`).
"""
function write_ldr_image(filename::String, image::HdrImage; gamma = 1.0)
    for h = 1:image.height
        for w = 1:image.width
            pix = get_pixel(image, w, h)
            color = ColorTypes.RGB{Float32}(
                pix.r^(1 / gamma),
                pix.g^(1 / gamma),
                pix.b^(1 / gamma),
            )
            image_copy = deepcopy(image)
            set_pixel!(image_copy, w, h, color)
        end
    end
    # Using save function from Images packages
    Images.save(filename, image.pixels)
end

"Parse image dimension from a PFM file."
function _parse_img_size(str::String)
    parts = split(str, " ")
    if length(parts) != 2
        throw(WrongPFMformat("invalid size of the image in PFM file."))
    end
    width, height = parse.(Int, parts)
    if width <= 0 || height <= 0
        throw(WrongPFMformat("size of the image must be positive."))
    end
    return width, height
end

"Parse endianness from a PFM file."
function _parse_endianness(str::String)
    value = parse(Float32, str)
    if value > 0
        return Float32(1.0)
    elseif value < 0
        return Float32(-1.0)
    else
        throw(WrongPFMformat("invalid endianness specification."))
    end
end

"Read 32-bit floating point number, i.e. read 4 bytes"
function _read_float(stream::IO, endianness::Float32)
    x = read(stream, UInt32)
    is_big_endian = endianness == 1.0
    # n: big-endian
    # l: little-endian
    # h: host endianness
    x = (is_big_endian == true) ? ntoh(x) : ltoh(x)
    reinterpret(Float32, x)
end

"""
    read_pfm_image(stream::IO)

Read a PFM Image from a stream and returns the corresponding HdrImage.
"""
function read_pfm_image(stream::IO)
    # Read the magic, expected "PF"
    magic = readline(stream)
    if magic != "PF"
        throw(WrongPFMformat("invalid magic in PFM file."))
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
end

"""
    read_pfm_image(filename::String)

Read a PFM Image from a file and returns the corresponding HdrImage.
"""
function read_pfm_image(filename::String)
    open(filename, "r") do io
        return read_pfm_image(io)
    end
end

"""
    read_ldr_image(filename::String)

Read a ldr Image (.png, .jpg, ...) from a file and returns the corresponding HdrImage.
"""
function read_ldr_image(filename::String)
    img_ldr = Images.load(filename)
    img_pfm = convert.(ColorTypes.RGB{Float32}, img_ldr)
    height, width = size(img_ldr)
    img = HdrImage(width, height, img_pfm)
    return img
end

"""
    ldr_to_pfm_image(filename::String, output_name::String)

Read a ldr Image (.png, .jpg, ...) from a file and save the corresponding HdrImage (.pfm) file.
"""
function ldr_to_pfm_image(filename::String, output_name::String)
    img = read_ldr_image(filename)
    write(output_name, img)
end
