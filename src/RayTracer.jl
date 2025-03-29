module RayTracer

import ColorTypes
import Images
import Base: +, *, ≈, write


export +,
    *,
    ≈,
    color_to_string,
    HdrImage,
    valid_coordinates,
    get_pixel,
    set_pixel!,
    write,
    little_endian,
    my_endian,
    check_endianness,
    WrongPFMformat,
    normalize_image,
    luminosity,
    log_average

const little_endian = Base.ENDIAN_BOM == 0x04030201 # true if the host is little endian, false otherwise

include("exceptions.jl")
include("colors.jl")
include("io.jl")

greet() = println("Hello World!")

end
