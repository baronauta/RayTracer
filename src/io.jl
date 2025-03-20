# Input and Output

# Writing Color to stream

function Base.write(io::IO, color::ColorTypes.RGB{Float32}; endianness = my_endian)

    check_endianness(endianness)
    # Convert a floating-point number to an integer for bynary writing
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
    check_endianness(endianness)
    open(filename, "w") do io
        write(io, image, endianness)
    end
end
