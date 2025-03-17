module RayTracer

import ColorTypes
import Base: +, *, ≈

export +, *, ≈, color_to_string, HdrImage, valid_coordinates, get_pixel, set_pixel!
include("colors.jl")

greet() = println("Hello World!")

end
