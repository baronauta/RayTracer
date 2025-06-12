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
        expected = join(exts, ", ")
        throw(
            ExtensionError("expected extension to be one of {$expected}, but found $(extname(filename))")
        )
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

