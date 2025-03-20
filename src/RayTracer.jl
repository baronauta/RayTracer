module RayTracer

import ColorTypes
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
    EndiannessWrongValueError,
    EndiannessZeroValueError,
    WrongFileExtension

const little_endian = Base.ENDIAN_BOM == 0x04030201 # true if the host is little endian, false otherwise
my_endian = 0.0
if little_endian
    my_endian = -1.0
else
    my_endian = 1.0
end
include("exceptions.jl")
include("colors.jl")
include("io.jl")

greet() = println("Hello World!")

end
