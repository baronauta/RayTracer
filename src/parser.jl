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
function _expect_symbol(instream::InputStream, symbol::AbstractString)
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
function _expect_number(instream::InputStream, scene::Scene)
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

"Read a token from the stream and check that it matches 'string', returning a string."
function _expect_string(instream::InputStream)
    token = read_token(instream)
    if !(isa(token, LiteralString))
        throw(
            GrammarError(
                token.location,
                "got '$token'  instead of a string",
            ),
        )
    end
    return token.string
end

"Read a token from the stream and check that it matches 'identifier'."
function _expect_identifier(instream::InputStream, identifier::AbstractString)
    token = read_token(instream)
    if !(isa(token, IdentifierToken)) || token.identifier != identifier
        throw(
            GrammarError(
                token.location,
                "got '$token'  instead of '$identifier'",
            ),
        )
    end
    return token.identifier
end

"Read a token form the stream and check that it is one of the keywords in the given list of keywords."
function _expect_keywords(instream::InputStream, keywords::Vector{KeywordEnum})
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
    _expect_symbol(instream, "[")
    x = expect_number(instream, scene)
    _expect_symbol(instream, ",")
    y = expect_number(instream, scene)
    _expect_symbol(instream, ",")
    z = expect_number(instream, scene)
    _expect_symbol(instream, "]")
    return Vec(x, y, z)
end

"Parse color as <r, g, b>, returning a 'ColorTypes.RGB{Float32}'."
function parse_color(instream::InputStream, scene::Scene)
    _expect_symbol(instream, "<")
    red = _expect_number(instream, scene)
    _expect_symbol(instream, ",")
    green = _expect_number(instream, scene)
    _expect_symbol(instream, ",")
    blue = _expect_number(instream, scene)
    _expect_symbol(input_file, ">")
    return RGB(red, green, blue)
end

"""
Parses a pigment expression: `uniform(...)`, `checkered(...)`, or `image("...")`.

Returns a `UniformPigment`, `CheckeredPigment`, or `ImagePigment`.  
Supports image formats: `.pfm`, `.jpg`, `.jpeg`, `.png`, `.tiff`, `.tif`.
"""
function parse_pigment(instream::InputStream, scene::Scene)
    keyword = _expect_keywords(instream, [IMAGE, UNIFORM, CHECKERED])
    _expect_symbol(instream, "(")
    # return a UniformPigment
    if keyword == UNIFORM
        color = parse_color(instream, scene)

        result = UniformPigment(color)
    # return a CheckeredPigment
    elseif keyword == CHECKERED
        color1 = parse_color(instream, scene)
        _expect_symbol(instream, ",")
        color2 = parse_color(instream, scene)
        _expect_symbol(instream, ",")
        number = _expect_number(instream, scene)

        result = CheckeredPigment(color1, color2, number)
    # return an ImagePigment
    elseif keyword == IMAGE
        filename = _expect_string(instream) 
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
    _expect_symbol(instream, ")")
    return result
end

"""
Parses a BRDF expression: `diffuse(...)` or `specular(...)`.

Returns a `DiffuseBRDF` or `SpecularBRDF` using the parsed pigment.
"""
function parse_brdf(instream::InputStream, scene::Scene)
    brdf = _expect_keywords(instream, [DIFFUSE, SPECULAR])
    _expect_symbol(instream, "(")
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