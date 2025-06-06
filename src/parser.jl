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
mutable struct Scene
    # `Material`s can be explicitly declared and named, e.g. `material ground_material(...)`. 
    # In contrast, other types like `Sphere` or `Plane` cannot be assigned to named variables.
    materials::Dict{String, Material} 
    world::World
    camera::Union{Camera, Nothing} # only one camera is allowed
    float_variables::Dict{String, AbstractFloat} #| Float variables defined externally or already defined in the scene file.
                                                 #| This is a float dictionarry so camera transformation parameters 
                                                 #| need to be passed has single floats (angle = angle, x_translation = ..., ...).
    overridden_variables::Set{String}  #| Names of variables defined externally (e.g., from the CLI).
                                       #| If re-encountered in scene.txt, their value is not overridden —
                                       #| the external value is preserved.

end

"A default `Scene` constructor"
function Scene()
    Scene(Dict{String, Material}(),
          World(),
          nothing,
          Dict{String, Float64}(),
          Set{String}())
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
    expect_symbol(instream, ">")
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
    pigment = parse_pigment(instream, scene)
    expect_symbol(instream, ")")
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
    expect_symbol(instream, ",")
    emitted_radiance = parse_pigment(instream, scene)
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
Parses a sphere definition from the input stream using the format:
`sphere(material_name, transformation(...))`. Looks up the material in
`scene.materials` and applies the parsed transformation.
Returning a `Sphere`.
"""
function parse_sphere(instream::InputStream, scene::Scene)
    # Example to be parsed;
    # sphere(sphere_material, translation([0, 0, 1]))
    expect_keywords(instream, [SPHERE])
    expect_symbol(instream, "(")
    material_name = expect_identifier(instream)
    if !haskey(scene.materials, material_name)
        throw(GrammarError(instream.location, "unknown material `$material_name`"))
    end
    expect_symbol(instream, ",")
    transformation = parse_transformation(instream, scene)
    expect_symbol(instream, "(")
    return Sphere(
        transformation, scene.materials[material_name]
    )
end

"""
Parses a plane definition from the input stream using the format:
`plane(material_name, transformation(...))`. Looks up the material in
`scene.materials` and applies the parsed transformation.
Returning a `Plane`.
"""
function parse_plane(instream::InputStream, scene::Scene)
    # Example to be parsed;
    # plane(ground_material, identity)
    expect_keywords(instream, [PLANE])
    expect_symbol(instream, "(")
    material_name = expect_identifier(instream)
    if !haskey(scene.materials, material_name)
        throw(GrammarError(instream.location, "unknown material `$material_name`"))
    end
    expect_symbol(instream, ",")
    transformation = parse_transformation(instream, scene)
    expect_symbol(instream, "(")
    return Plane(
        transformation, scene.materials[material_name]
    )
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

"""
    parse_scene(instream::InputStream; variables::Dict{String, AbstractFloat})

Parses a scene description from the given input stream and constructs a `Scene` object.

# Behavior
- Reads tokens from the stream sequentially until EOF.
- Recognizes keywords.
- Parses and adds corresponding elements to the scene.
- Variable handling rules:
  - External variables provided via `variables` are preserved and cannot be overridden by the scene file.
  - Variables defined internally inside the scene file can only be defined once.
  - Redefinition of an internal variable in the scene file results in a parse error.
- Only one camera definition is allowed; attempts to define multiple cameras raise an error.

# Returns
- A `Scene` object representing the parsed scene.

# Throws
- `GrammarError` if the input contains syntax errors, redefinitions, or unexpected tokens.
"""
function parse_scene(instream::InputStream; variables::Dict{String, AbstractFloat})
    # This function parses scene.txt and builds the world to render.
    # Some variables can be defined externally (e.g., via CLI) and others directly inside scene.txt
    #
    # Variable resolution rules:
    # - If a variable is defined externally and redefined in scene.txt, the external value is kept.
    # - If a variable is not defined externally, it can be defined once inside scene.txt.
    # - If an internal variable is redefined later in the file, that is an error.

    scene = Scene()

    # Copy external variables into the scene
    scene.float_variables = deepcopy(variables)
    # Track the names of externally defined variables
    scene.overridden_variables = Set(keys(variables))

    # Parse the file token by token
    while true
        token = read_token(instream)
        # Stop if end of file is reached
        isnothing(token) && break

        # The first token of each construct must be a keyword, either a definition of var or a creation of object
        #       (e.g., FLOAT, MATERIAL, SPHERE, etc.)
        # Note: using 'expect_keywords' would require first read the token and check if reached end of file, 
        #       then unread_token and then use expect_keywords; this is simpler and clearer:
        if !(isa(token, KeywordToken))
            throw(
                GrammarError(
                    token.location,
                    "expected a keyword instead of '$token'",
                ),
            )
        end

        if token.keyword == FLOAT
            # memorize token name and value
            var_name = expect_identifier(instream)
            var_loc = instream.location
            expect_symbol(instream, "(")
            var_val = expect_number(instream, scene)
            expect_symbol(instream, ")")

            # do the previously mentioned check:
            # Only allow internal variables to be defined once; redefinitions are errors
            if !(var_name in scene.overridden_variables)
                if haskey(scene.float_variables, var_name)
                    throw(GrammarError(
                        var_loc,
                        "variable '$var_name' cannot be redefined",
                    ))
                end
                scene.float_variables[var_name] = var_val
            end

        # Handle other recognized keywords
        elseif token.keyword == MATERIAL
            material_name, material = parse_material(instream, scene)
            scene.materials[material_name] = material

        elseif token.keyword == PLANE
            add!(scene.world, parse_plane(instream, scene))

        elseif token.keyword == SPHERE
            add!(scene.world, parse_sphere(instream, scene))

        elseif token.keyword == CAMERA
            # Only one camera can be defined in the scene
            !isnothing(scene.camera) && throw(GrammarError(token.location, "You cannot define more than one camera"))
            scene.camera = parse_camera(instream, scene)
        else
            # Raise an error for any unexpected keyword
            throw(GrammarError(token.location, "Unexpected keyword: $token"))
        end
    end
    return scene
end