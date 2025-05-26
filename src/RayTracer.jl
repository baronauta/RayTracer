module RayTracer

import ColorTypes
import Images

# Import the Base functions to extend them with new methods.
# Since these functions are part of Base (which is always loaded),
# there is no need to export them from this package.
# All extended methods will be available automatically when using the package.
import Base: +, -, *, ≈
import Base: write, show

export RGB, HdrImage, WHITE, BLACK, GRAY, RED, GREEN, BLUE
export read_pfm_image
export Point, Vec, Vec2D, Normal, VEC_X, VEC_Y, VEC_Z
export dot, cross
export Transformation, HomMatrix, translation, rotation_x, rotation_y, rotation_z, scaling
export Ray
export OrthogonalCamera, PerspectiveCamera
export ImageTracer
export Shape, HitRecord, Plane, Sphere
export World, add!
export UniformPigment, CheckeredPigment, ImagePigment
export Material
export OnOff_Tracer, Flat_Tracer, Path_Tracer

export WrongPFMformat, ToneMappingError, RuntimeError, GeometryError 

export IS_LITTLE_ENDIAN, HOST_ENDIANNESS

# Determine if the host system uses little endian byte order
const IS_LITTLE_ENDIAN = Base.ENDIAN_BOM == 0x04030201

# Set endianness flag: -1.0 for little endian, 1.0 for big endian
const HOST_ENDIANNESS = IS_LITTLE_ENDIAN ? -1.0 : 1.0

include("exceptions.jl")
include("colors.jl")
include("io.jl")
include("geometry.jl")
include("transformation.jl")
include("cameras.jl")
include("material.jl")
include("shapes.jl")
include("world.jl")
include("demo.jl")
include("pcg.jl")
include("render.jl")

# ─────────────────────────────────────────────────────────────
# Parameters for PFM file conversion
# ─────────────────────────────────────────────────────────────
mutable struct Parameters
    input_pfm_file_name::String
    factor::Real
    gamma::Real
    output_png_file_name::String
    mean_type::Symbol
    weights::Array{Real,1}
    delta::Real
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
        throw(
            RuntimeError(
                """\n
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
""",
            ),
        )

    end
    factor = 0.0
    gamma = 0.0
    input_pfm_file_name = A[1]
    output_png_file_name = A[4]
    try
        factor = parse(Float32, A[2])
    catch e
        if isa(e, ArgumentError)
            throw(
                RuntimeError(
                    "Invalid factor ($(A[2])), it must be a floating-point number.",
                ),
            )
        end
    end
    try
        gamma = parse(Float32, A[3])
    catch e
        if isa(e, ArgumentError)
            throw(
                RuntimeError(
                    "Invalid gamma ($(A[3])), it must be a floating-point number.",
                ),
            )
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
            throw(
                RuntimeError(
                    "Invalid weights ($(A[6])), it must be a floating-point numbers array, correct example: \"[1.0, 2.0, 3.0]\".",
                ),
            )
        end
        try
            delta = parse(Float32, A[7])
        catch
            throw(
                RuntimeError(
                    "Invalid delta ($(A[7])), it must be a floating-point number.",
                ),
            )

        end


    end

    return Parameters(
        input_pfm_file_name,
        factor,
        gamma,
        output_png_file_name,
        mean_type,
        weights,
        delta,
    )

end

end
