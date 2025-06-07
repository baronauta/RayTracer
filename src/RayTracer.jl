
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
export DiffuseBRDF, SpecularBRDF
export onoff_tracer, flat_tracer, path_tracer, my_renderer

export WrongPFMformat, ToneMappingError, RuntimeError, GeometryError, GrammarError
export Token, KeywordToken, LiteralNumberToken, StringToken, SymbolToken, IdentifierToken

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
include("pcg.jl")
include("material.jl")
include("shapes.jl")
include("world.jl")
include("demo.jl")
include("render.jl")
include("pfm2image.jl")
include("lexer.jl")
include("parser.jl")

end
