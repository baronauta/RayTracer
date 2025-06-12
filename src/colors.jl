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

"Wrapper function to ColorTypes.RGB{Float32}."
function RGB(r, g, b)
    ColorTypes.RGB{Float32}(r, g, b)
end

"Show an RGB color"
function Base.show(io::IO, c::ColorTypes.RGB)
    print(io, "ColorTypes.RGB(r=$(c.r), g=$(c.g), b=$(c.b))")
end

function Base.show(io::IO, ::MIME"text/plain", c::ColorTypes.RGB)
    show(io, c)
end

const WHITE = RGB(1.0, 1.0, 1.0)
const BLACK = RGB(0.0, 0.0, 0.0)
const GRAY = RGB(0.5, 0.5, 0.5)
const RED = RGB(1.0, 0.0, 0.0)
const GREEN = RGB(0.0, 1.0, 0.0)
const BLUE = RGB(0.0, 0.0, 1.0)

"Add two RGB colors, returning a new RGB color."
function +(x::ColorTypes.RGB, y::ColorTypes.RGB)
    RGB(x.r + y.r, x.g + y.g, x.b + y.b)
end

"Multiply a RGB color by a scalar, returning a new RGB color."
function *(s::Real, c::ColorTypes.RGB)
    RGB(s * c.r, s * c.g, s * c.b)
end

"Component-wise product between two RGB colors, returning a new RGB color."
function *(x::ColorTypes.RGB, y::ColorTypes.RGB)
    RGB(x.r * y.r, x.g * y.g, x.b * y.b)
end

"Check if two RGB colors are approximately equal."
function ≈(x::ColorTypes.RGB, y::ColorTypes.RGB)
    isapprox(x.r, y.r, rtol = 1e-3, atol = 1e-3) &&
        isapprox(x.g, y.g, rtol = 1e-3, atol = 1e-3) &&
        isapprox(x.b, y.b, rtol = 1e-3, atol = 1e-3)
end
