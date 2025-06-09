
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
# Defining new customized Exceptions with custom 'show' methods
# ─────────────────────────────────────────────────────────────
#---
"""
    struct WrongPFMformat <: Exception
Custom exception for handling incorrect PFM file format errors.

# Fields
- `msg::String`: Error message describing the issue.
"""
struct WrongPFMformat <: Exception
    msg::String
end

"Show WrongPFMformat"
function Base.show(io::IO, err::WrongPFMformat)
    red_bold = Crayons.Crayon(foreground=:red, bold=true)
    yellow_bold = Crayons.Crayon(foreground=:yellow, bold=true)
    
    print(io,
        red_bold("WrongPFMformat: "),
        yellow_bold(err.msg)
    )
end

#---
"""
    struct ToneMappingError <: Exception
Custom exception for errors encountered during tone mapping operations.

# Fields
- `msg::String`: Error message describing the issue.
"""
struct ToneMappingError <: Exception
    msg::String
end

"Show ToneMappingError"
function Base.show(io::IO, err::ToneMappingError)
    red_bold = Crayons.Crayon(foreground=:red, bold=true)
    yellow_bold = Crayons.Crayon(foreground=:yellow, bold=true)
    
    print(io,
        red_bold("ToneMappingError: "),
        yellow_bold(err.msg)
    )
end

#---
"""
    struct RuntimeError <: Exception
Custom exception for errors encountered while running RayTracer, after being precompiled.

# Fields
- `msg::String`: Error message describing the issue.
"""
struct RuntimeError <: Exception
    msg::String
end

"Show RuntimeError"
function Base.show(io::IO, err::RuntimeError)
    red_bold = Crayons.Crayon(foreground=:red, bold=true)
    yellow_bold = Crayons.Crayon(foreground=:yellow, bold=true)
    
    print(io,
        red_bold("RuntimeError: "),
        yellow_bold(err.msg)
    )
end

#---
"""
    struct GeometryError <: Exception
Custom exception for errors encountered during geometry operations (ex: comparing Vector and Point).

# Fields
- `msg::String`: Error message describing the issue.
"""
struct GeometryError <: Exception
    msg::String
end

"Show GeometryError"
function Base.show(io::IO, err::GeometryError)
    red_bold = Crayons.Crayon(foreground=:red, bold=true)
    yellow_bold = Crayons.Crayon(foreground=:yellow, bold=true)
    
    print(io,
        red_bold("GeometryError: "),
        yellow_bold(err.msg)
    )
end