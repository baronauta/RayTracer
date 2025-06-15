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

abstract type CustomException <: Exception end

function Base.show(io::IO, err::CustomException)
    red_bold = Crayons.Crayon(foreground=:red, bold=true)
    yellow_bold = Crayons.Crayon(foreground=:yellow, bold=true)
    
    print(io,
        red_bold(string(nameof(typeof(err)))*": "),
        yellow_bold(err.msg)
    )
end

struct ExtensionError <: CustomException
    msg::String
end

"Check if filename ends with any allowed extension (case-insensitive)"
function expected_extension(filename::String, exts::Vector{String})
    allowed = any(endswith(lowercase(filename), lowercase(ext)) for ext in exts)
    if !allowed
        expected_msg = length(exts) == 1 ?
            "expected extension to be $(exts[1])" :
            "expected extension to be one of: " * join(exts, ", ")
        
        throw(ExtensionError("$expected_msg, but found $(splitext(filename)[2])"))
    end
end


"""
    struct RuntimeError <: CustomException
Custom exception for errors encountered while running RayTracer, after being precompiled.

# Fields
- `msg::String`: Error message describing the issue.
"""
struct RuntimeError <: CustomException
    msg::String
end

"""
    struct GeometryError <: CustomException
Custom exception for errors encountered during geometry operations (ex: comparing Vector and Point).

# Fields
- `msg::String`: Error message describing the issue.
"""
struct GeometryError <: CustomException
    msg::String
end

# --- Warning ---
"Print a warning message to the standard output in yellow text."
function print_warning(msg)
    yellow_bold = Crayons.Crayon(foreground=:yellow, bold=true)
    yellow = Crayons.Crayon(foreground=:yellow, bold=false)
    
    print(yellow_bold("Warning: "))
    println(yellow(msg))
end


# ─────────────────────────────────────────────────────────────
# NAME CREATION HELPER FUNCTIONS
# ─────────────────────────────────────────────────────────────

#--- parsing extension functions ---

"Check if the input name is a valid scene file name."
function check_scene_name(path::String)
    blue = "\u001b[34m"
    yellow_bold = "\e[1;33m"
    !isfile(path) && throw(RuntimeError("the file $blue$path$yellow_bold does not exist. Please insert a valid '.txt' scene file."))
    expected_extension(path, [".txt"])
end

"""
Extracts the file extension from a given `filename`.

# Returns
- The extension string (including the dot), e.g. ".png", or `nothing` if no extension is found.
"""
    function get_extension_if_given(filename::String)
        ext = splitext(filename)[2]
        return isempty(ext) ? nothing : ext
    end

"""
Determines the appropriate file extension to use for output.

# Returns
- The extension to use (including the dot), giving priority to the explicit `extension`.
- If no extension specified and none in filename, defaults to ".png".

# Notes
- If both filename and explicit extension have different extensions, a warning is printed and explicit extension is used.
"""
    function choose_ext(filename::String, extension::String)
        # Extract the extension from the output name, if it has one
        ext_in_filename = get_extension_if_given(filename)

        # Case 1: No extension was passed via --extension
        if extension == ""
            # No extension in output name → use default ".png"
            isnothing(ext_in_filename) && return ".png"

            # Extension found in output name → use that
            !isnothing(ext_in_filename) && return ext_in_filename
            
        else # Case 2: --extension was explicitly passed

            # Both extensions are present and they differ → show a warning
            if(!isnothing(ext_in_filename) && (extension != ext_in_filename))
                @warn "\n⚠️  Warning: extension in output name ('$ext_in_filename') doesn't match the one specified ('$extension'). Using the specified one.\n"
            end
            return extension
        end
    end
#--- choose the right name ---
"""
Constructs output file paths and directories based on input parameters.

# Arguments
- `output_name::String`: The base name of the output file.
- `extension::String`: The desired file extension (may be empty).
- `scene_file::String`: Path to the scene file used for rendering.
- `tracer::String`: A prefix string indicating the tracer type (used in default naming).

# Returns
- `extension`: The chosen file extension (including the dot).
- `ldr_path`: Full path for the tone-mapped output image file.
- `pfm_path`: Full path for the high dynamic range `.pfm` output file.

# Behavior
- If no output name is provided, creates a timestamped name inside a directory named after the scene file.
- Ensures the output directory exists.
- If output name is provided, uses it to build output paths with correct extensions.
"""
function choose_name(output_name::String, extension::String, scene_file::String, tracer::String)
    # check if an output name is declared, if not use timestamp for default.
    # For default name i want to create a folder with the scene name.
    if isempty(output_name)
        extension = choose_ext(output_name, extension) # here i choose the default or the passed one 
        scene_name = splitext(basename(scene_file))[1]
        timestamp = Dates.format(Dates.now(), "yyyy-mm-dd_HHMMSS")
        output_name = "$(tracer)_$timestamp"
        base_path = "render_$(scene_name)"

        # make the path for output images
        mkpath(base_path)
        ldr_path = joinpath(base_path, output_name * extension)
        pfm_path = joinpath(base_path, output_name * ".pfm")

        return extension, ldr_path, pfm_path
    else
        extension = choose_ext(output_name, extension)

        # make the path for output images
        name = splitext(output_name)[1]
        ldr_path = joinpath(name * extension)
        pfm_path = joinpath(name * ".pfm")

        return extension, ldr_path, pfm_path
    end
end

#--- choose default name for tonemapped ---

"""
Generates a descriptive name for a tonemapped image based on the specified mean type and parameters.

Returns a string encoding the tonemapping settings.
"""
function tonemapping_name(
    name::String,
    mean::String,
    weights::Union{Nothing, Vector{Float64}},
    a::Float64,
    gamma::Float64,
)
    # convert mean to a Symbol
    symbol_mean = Symbol(mean)
    # Initialize mean and weights strings
    mean_str = ""
    weights_str = ""

    # Map mean type to abbreviation
    if symbol_mean == :max_min
        mean_str = "mxmn"
    elseif symbol_mean == :arithmetic
        mean_str = "arith"
    elseif symbol_mean == :weighted
        mean_str = "wavg"
        # Round weights to 2 decimals and format as [x,y,z], 
        # no need to check if weights is nothing, not accepted from functions above.
        rounded_weights = round.(weights; digits=2)
        weights_str = "_w[" * join(rounded_weights, ",") * "]"
    elseif symbol_mean == :distance
        mean_str = "dist"
    else
        mean_str = mean
    end

    # Build final filename
    new_name = "$(name)-$(mean_str)$(weights_str)_a$(round(a, digits=2))_g$(round(gamma, digits=2))"

    return new_name
end
