
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
# Parameters for PFM file conversion
# ─────────────────────────────────────────────────────────────
mutable struct Conversion_Params
    input_pfm_file_name::String
    factor::Real
    gamma::Real
    output_png_file_name::String
    mean_type::Symbol
    weights::Array{Real,1}
    delta::Real
end

# correct usage message

# correct usage message
message_error = """\n
 ------------------------------------------------------------
 Correct command usage:
    julia pfm2image INPUT_PFM_FILE FACTOR GAMMA OUTPUT_PNG_FILE [OPTIONS]

    Arguments:
    - INPUT_PFM_FILE     Path to the input .pfm file
    - FACTOR             Constant to tune the image luminosity
    - GAMMA              monitor correction value
    - OUTPUT_PNG_FILE    Path to the output file

    Options (Advanced mode):
    - MEAN_TYPE SYMBOL   Type of mean used in luminosity (default: :max_min)
    - WEIGHTS VECTOR     Weights for weighted luminosity
    - DELTA FLOAT        Small offset to stabilize log_average near zero values

 Notes:
 - MEAN_TYPE will be interpreted as a Julia Symbol
 - WEIGHTS must be passed as a quoted Julia array
   Example: "[1.0, 2.0, 3.0]"
------------------------------------------------------------
"""


"""
    function Conversion_Params(A)

Parses and validates command-line arguments in basic or advanced mode.

# Arguments:
- `A`: Array of strings representing the command-line arguments.
  - `factor`: multiplied factor in `log_avarage`
  - `gamma`: monitor correction
  - `mean_type`: type of mean used in `luminosity`
  - `weights`: used in weighted `luminosity`
  - `delta`: usefull to make - `log_avarage` near 0 values
# Returns:
- A `Conversion_Params` struct with the parsed values:
  - `input_pfm_file_name`, `factor`, `gamma`, `output_png_file_name`, `mean_type`, `weights`, `delta`.
# Errors:
- Throws errors for invalid types or incorrect argument count.
"""
function Conversion_Params(A)
    if (length(A) != 4) && (length(A) != 7)
        throw(RuntimeError(message_error))

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
                    "invalid factor ($(A[2])), it must be a floating-point number.",
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
                    "invalid gamma ($(A[3])), it must be a floating-point number.",
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
                    "invalid weights ($(A[6])), it must be a floating-point numbers array, correct example: \"[1.0, 2.0, 3.0]\".",
                ),
            )
        end
        try
            delta = parse(Float32, A[7])
        catch
            throw(
                RuntimeError(
                    "invalid delta ($(A[7])), it must be a floating-point number.",
                ),
            )

        end


    end

    return Conversion_Params(
        input_pfm_file_name,
        factor,
        gamma,
        output_png_file_name,
        mean_type,
        weights,
        delta,
    )

end
