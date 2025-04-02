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
    normalize_image!,
    luminosity,
    log_average,
    Parameters,
    ToneMappingError,
    RuntimeError,
    read_pfm_image,
    clamp_image!,
    write_ldr_image

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

"""
    function Parameters(A)

Parses and validates command-line arguments in basic or advanced mode.

### Arguments:
- `A`: Array of strings representing the command-line arguments.
  - `factor`: multiplied factor in `log_avarage`
  - `gamma`: monitor correction
  - `mean_type`: type of mean used in `luminosity`
  - `weights`: used in weighted `luminosity`
  - `delta`: usefull to make - `log_avarage` near 0 values
### Returns:
- A `Parameters` struct with the parsed values:
  - `input_pfm_file_name`, `factor`, `gamma`, `output_png_file_name`, `mean_type`, `weights`, `delta`.

### Errors:
- Throws errors for invalid types or incorrect argument count.
"""
function Parameters(A)
    if (length(A) != 4) && (length(A) != 7)
        throw(RuntimeError("""\n
        ------------------------------------------------------------
        Correct command usage:
           - Basic mode:
             julia RayTracer INPUT_PFM_FILE FACTOR GAMMA OUTPUT_PNG_FILE
       
           - Advanced mode:
             julia RayTracer INPUT_PFM_FILE FACTOR GAMMA OUTPUT_PNG_FILE MEAN_TYPE WEIGHTS DELTA
       
        Advanced notes:
           - MEAN_TYPE will be converted to a Symbol (default = max_min)
           - WEIGHTS must be a vector of numbers enclosed in quotes:
             Correct example: "[1.0, 2.0, 3.0]"
       
        Number of arguments received: $(length(A))
       ------------------------------------------------------------
       """))

    end
    factor=0.0
    gamma=0.0
    input_pfm_file_name = A[1]
    output_png_file_name = A[4]
    try
        factor = parse(Float32, A[2])
    catch e
        if isa(e, ArgumentError)
            throw(RuntimeError("Invalid factor ($(A[2])), it must be a floating-point number."))
        end
    end
    try
        gamma = parse(Float32, A[3])
    catch e
        if isa(e, ArgumentError)
            throw(RuntimeError("Invalid gamma ($(A[3])), it must be a floating-point number."))
        end
    end
    if length(A) == 4
        mean_type = :max_min
        weights = [1.0, 1.0, 1.0]
        delta = 1e-10

    else
        mean_type = Symbol(A[5])
        try
            weights = parse.(Float32, split(strip(A[6], ['[', ']']), ","))
        catch
            throw(RuntimeError("Invalid weights ($(A[6])), it must be a floating-point numbers array, correct example: \"[1.0, 2.0, 3.0]\"."))
        end
        try
            delta = parse(Float32, A[7])
        catch
            throw(RuntimeError("Invalid delta ($(A[7])), it must be a floating-point number."))

        end
        

    end
       
    return Parameters(input_pfm_file_name, factor, gamma, output_png_file_name, mean_type, weights, delta)
    
end

end