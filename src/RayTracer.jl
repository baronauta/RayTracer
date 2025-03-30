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
    log_average,
    Parameters,
    ToneMappingError,
    RuntimeError

const little_endian = Base.ENDIAN_BOM == 0x04030201 # true if the host is little endian, false otherwise

include("exceptions.jl")
include("colors.jl")
include("io.jl")

# Parameters
mutable struct Parameters
    input_pfm_file_name :: String
    factor:: Real
    gamma :: Real
    output_png_file_name :: String
    mean_type :: Symbol
    weights ::Array{Real, 1}
    delta :: Real
end

function Parameters(A)

    if (length(A) != 5) && (length(A) != 7)
        throw(RuntimeError("""\n
        ------------------------------------------------------------
        Correct command usage:
           - Basic mode:
             julia RayTracer INPUT_PFM_FILE FACTOR GAMMA OUTPUT_PNG_FILE
       
           - Advanced mode:
             julia RayTracer INPUT_PFM_FILE FACTOR GAMMA OUTPUT_PNG_FILE MEAN_TYPE WEIGHTS DELTA
       
        Advanced notes:
           - MEAN_TYPE must be a symbol(default = :max_min)
           - WEIGHTS must be a vector of numbers enclosed in quotes:
             Correct example: "[1.0, 2.0, 3.0]"
       
        Number of arguments received: $(length(A))
       ------------------------------------------------------------
       """))

    end
    factor=0.0
    gamma=0.0
    try
        factor = parse(Float32, A[2])
        gamma = parse(Float32, A[3])
    catch e
        if isa(e, ArgumentError)
            throw(RuntimeError("Invalid Type of $(A[2]), it must be a floating-point number."))
        end
    end
    input_pfm_file_name = A[1]
    output_png_file_name = A[4]
    if length(A) == 4
        mean_type = :max_min
        weights = [1.0, 1.0, 1.0]
        delta = 1e-10

    else
        mean_type = Symbol(A[5])
        weights = parse.(Float32, split(strip(A[6], ['[', ']']), ","))
        delta = parse(Float32, A[7])

    end
       
    return Parameters(input_pfm_file_name, factor, gamma, output_png_file_name, mean_type, weights, delta)
    
end

end