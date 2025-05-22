
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

import Base: +, -, *, ≈
import Base: write, show
import ColorTypes
import Images

export Point, Vec, Normal, VEC_X, VEC_Y, VEC_Z, Ray
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
    write_ldr_image,
    GeometryError

export HdrImage,
    OrthogonalCamera,
    PerspectiveCamera,
    translation,
    scaling,
    Vec,
    ImageTracer,
    Sphere,
    World,
    fire_ray,
    RGB,
    ray_intersection,
    fire_all_rays!,
    rotation_z,
    demo,
    Conversion_Params,
    demo_Params,
    generate_single_image,
    generate_video,
    make_video

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
include("shapes.jl")
include("world.jl")
include("demo.jl")
include("pfm2image.jl")
end
