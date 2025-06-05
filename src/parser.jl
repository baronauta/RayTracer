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
#
#_______________________________________________________________________________________

"A scene read from a scene file."
struct Scene
    materials::Dict{String, Material}
    world::World
    camera::Union{Camera, Nothing}
    float_variables::Dict{String, AbstractFloat}
end

"Read a token from the stream and check that it matches 'symbol'."
function expect_symbol(instream::InputStream, symbol::AbstractString)
    token = read_token(instream)
    if !(isa(token, SymbolToken)) || token.symbol != symbol
        throw(
            GrammarError(
                token.location,
                "got '$token'  instead of '$symbol'",
            ),
        )
    end
    return token.symbol
end

"""
Reads a token from the input stream and returns its numeric value.
Accepts a `LiteralNumber` or an `IdentifierToken` matching a variable in `scene.float_variables`.  
"""
function expect_number(instream::InputStream, scene::Scene)
    token = read_token(instream)
    if isa(token, LiteralNumber)
        return token.number
    elseif isa(token, IdentfierToken)
        variable_name = token.identifier
        if haskey(scene.float_variables, variable_name)
            return scene.float_variables[variable_name]
        else
            throw(
                GrammarError(
                    token.location,
                    "expected number instead of '$token'.",
                ),
            )
        end
    end
    return token.number
end

"Read a token from the stream and check that it is a String, returning a String."
function expect_string(instream::InputStream)
    token = read_token(instream)
    if !(isa(token, LiteralString))
        throw(
            GrammarError(
                token.location,
                "expected a string, got '$token'",
            ),
        )
    end
    return token.string
end

"Read a token from the stream and check that it is an 'identifier', returning a String."
function expect_identifier(instream::InputStream)
    token = read_token(instream)
    if !(isa(token, IdentifierToken))
        throw(
            GrammarError(
                token.location,
                "expected an identifier, got '$token'",
            ),
        )
    end
    return token.identifier
end

"Read a token form the stream and check that it is one of the keywords in the given list of keywords."
function expect_keywords(instream::InputStream, keywords::Vector{KeywordEnum})
    token = read_token(instream)

    if !(isa(token, KeywordToken))
        throw(
            GrammarError(
                token.location,
                "expected a keyword instead of '$token'",
            ),
        )
    end

    if !(token.keyword in keywords)
        throw(
            GrammarError(
                token.location,
                "expected one of these keywords $keywords instead of '$token'."  
            )
        )
    end
    return token.keyword
end

"Parse a vector as [x, y, z], returning a 'Vec'."
function parse_vector(instream::InputStream, scene::Scene)
    expect_symbol(instream, "[")
    x = expect_number(instream, scene)
    expect_symbol(instream, ",")
    y = expect_number(instream, scene)
    expect_symbol(instream, ",")
    z = expect_number(instream, scene)
    expect_symbol(instream, "]")
    return Vec(x, y, z)
end

"Parse color as <r, g, b>, returning a 'ColorTypes.RGB{Float32}'."
function parse_color(instream::InputStream, scene::Scene)
    expect_symbol(instream, "<")
    red = expect_number(instream, scene)
    expect_symbol(instream, ",")
    green = expect_number(instream, scene)
    expect_symbol(instream, ",")
    blue = expect_number(instream, scene)
    expect_symbol(input_file, ">")
    return RGB(red, green, blue)
end

"""
Parses a pigment expression: `uniform(...)`, `checkered(...)`, or `image("...")`.

Returns a `UniformPigment`, `CheckeredPigment`, or `ImagePigment`.  
Supports image formats: `.pfm`, `.jpg`, `.jpeg`, `.png`, `.tiff`, `.tif`.
"""
function parse_pigment(instream::InputStream, scene::Scene)
    keyword = expect_keywords(instream, [IMAGE, UNIFORM, CHECKERED])
    expect_symbol(instream, "(")
    # return a UniformPigment
    if keyword == UNIFORM
        color = parse_color(instream, scene)

        result = UniformPigment(color)
    # return a CheckeredPigment
    elseif keyword == CHECKERED
        color1 = parse_color(instream, scene)
        expect_symbol(instream, ",")
        color2 = parse_color(instream, scene)
        expect_symbol(instream, ",")
        number = expect_number(instream, scene)

        result = CheckeredPigment(color1, color2, number)
    # return an ImagePigment
    elseif keyword == IMAGE
        filename = expect_string(instream) 
        # need to separate cases where the user pass a pfm image (no need to convert) 
        #     or a ldr image (need conversion to pfm first)
        if endswith(lowercase(filename),".pfm")
            image = read_pfm_image(filename)
        elseif any(endswith(lowercase(filename), ext) for ext in [".jpg", ".jpeg", ".png", ".tiff", ".tif"])
            image = read_ldr_image(filename)
        else
            throw(GrammarError(instream.location, "Unexpected image format, plese use PFM, jpg, tif, or png"))
        end

        result = image

    else
        throw(GrammarError(instream.location, "Invalid pigment keyword"))
    end
    expect_symbol(instream, ")")
    return result
end

"""
Parses a BRDF expression: `diffuse(...)` or `specular(...)`.

Returns a `DiffuseBRDF` or `SpecularBRDF` using the parsed pigment.
"""
function parse_brdf(instream::InputStream, scene::Scene)
    brdf = expect_keywords(instream, [DIFFUSE, SPECULAR])
    expect_symbol(instream, "(")
    pigment = parse_pigment(input_file, scene)
    expect_symbol(input_file, ")")
    if brdf == DIFFUSE
        return DiffuseBRDF(pigment)
    elseif brdf_keyword == SPECULAR
        return SpecularBRDF(pigment)
    else
        throw(GrammarError(instream.location, "Invalid BRDF keyword"))
    end
end

"""
Parse material as `material sky_material(brdf, emitted_radiance)`, 
returning the identifier and the `Material`.
"""
function parse_material(instream::InputStream, scene::Scene)
    # Example to be parsed:
    # material sky_material(
    #     diffuse(image("sky-dome.pfm")),
    #     uniform(<0.7, 0.5, 1>)
    # )
    expect_keywords(instream, [MATERIAL])
    name = expect_identifier(instream)
    expect_symbol(instream, "(")
    brdf = parse_brdf(instream, scene)
    expect_symbol(input_file, ",")
    emitted_radiance = parse_pigment(input_file, scene)
    expect_symbol(instream, ")")
    return name, Material(brdf, emitted_radiance)
end

"""
Parses one or more transformations: identity, translation, rotation (x/y/z), or scaling.

Returns a final composed `Transformation`.
"""
function parse_transformation(instream::InputStream, scene::Scene)
    result = Transformation(HomMatrix(IDENTITY_MATR4x4), HomMatrix(IDENTITY_MATR4x4))
    # transformation can be composed, try to do that until breaking
    while true
        transformation = expect_keywords(instream, [IDENTITY, TRANSLATION, ROTATION_X, ROTATION_Y, ROTATION_Z, SCALING])
        if transformation == IDENTITY
            # no need to do anything

        elseif transformation == TRANSLATION
            expect_symbol(instream, "(")
            result *= translation(parse_vector(instream, scene))
            expect_symbol(instream, ")")

        elseif transformation == ROTATION_X
            expect_symbol(instream, "(")
            result *= rotation_x(expect_number(instream, scene))
            expect_symbol(instream, ")")

        elseif transformation == ROTATION_Y
            expect_symbol(instream, "(")
            result *= rotation_y(expect_number(instream, scene))
            expect_symbol(instream, ")")

        elseif transformation == ROTATION_Z
            expect_symbol(instream, "(")
            result *= rotation_z(expect_number(instream, scene))
            expect_symbol(instream, ")")

        elseif transformation == SCALING
            expect_symbol(instream, "(")
            x = expect_number(instream, scene)
            expect_symbol(instream, ",")
            y = expect_number(instream, scene)
            expect_symbol(instream, ",")
            z = expect_number(instream, scene)
            expect_symbol(instream, ")")
            result *= scaling(x,y,z)
        else
            throw(GrammarError(instream.location, "Invalid transformation keyword"))
        end

        # see next token, if not for a transformation composition brake the cicle
        next_token = read_token(instream) 
        if !(isa(token, SymbolToken)) || token.symbol != "*"
            unread_token(instream, next_token)
            break
        end
    end
    return result
end

"""
Parses a camera expression:  
- `perspective(distance, aspect_ratio, transformation)`  
- `orthogonal(distance, aspect_ratio, transformation)`

Returns a `PerspectiveCamera` or `OrthogonalCamera` accordingly.
"""
function parse_camera(instream::InputStream, scene::Scene)
    expect_symbol(instream, "(")
    cam_token = expect_keywords(instream, [PERSPECTIVE, ORTHOGONAL])
    expect_symbol(instream, ",")
    distance = expect_number(instream, scene)
    expect_symbol(instream, ",")
    aspect_ratio = expect_number(instream, scene)
    expect_symbol(instream, ",")
    transformation = parse_transformation(instream, scene)
    expect_symbol(instream, ")")
    if cam_token == PERSPECTIVE
        camera = PerspectiveCamera(distance, aspect_ratio, transformation)
    elseif cam_token == ORTHOGONAL
        camera = OrthogonalCamera(aspect_ratio, transformation)
    else
        throw(GrammarError(instream.location, "Invalid camera keyword"))
    end
    return camera
end