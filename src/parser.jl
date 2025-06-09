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


# --- Scene ---
"""
A container representing a scene parsed from a scene description file.

# Fields
- `materials::Dict{String, Material}`: a dictionary mapping identifiers to `Material` objects.

- `world::World`: the top-level container holding all scene geometry.

- `camera::Union{Camera, Nothing}`: a camera for the scene (only one allowed).

- `float_variables::Dict{String, AbstractFloat}`: a dictionary that stores all named float variables used in the scene, mapping variable names to their respective float values.

- `overridden_variables::Set{String}`: names of externally defined variables whose values are preserved when encountered again.

# Note
- `Material`s can be explicitly declared and named, e.g. `material ground_material(...)`.  
  In contrast, concrete shape types (e.g., `Sphere` and `Plane`) are not assigned to named variables;  
  instead, they are stored as elements in the `world`’s list of shapes.

- The `camera` field can also be `nothing` because the chosen camera is parsed at runtime,  
  so it is initially set to `nothing`.
"""
mutable struct Scene
    materials::Dict{String,Material}
    world::World
    camera::Union{Camera,Nothing}
    float_variables::Dict{String,AbstractFloat}
    overridden_variables::Set{String}  #| Names of variables defined externally (e.g., from the CLI).
    #| If re-encountered in scene.txt, their value is not overridden —
    #| the external value is preserved.

end

"""
Create a default, empty `Scene` instance.

# Description
Initializes a `Scene` with:

- an empty dictionary of named `Material`s,
- a new empty `World`,
- no camera (`nothing`),
- an empty dictionary for float variables (`Dict{String, Float64}()`),
- an empty set of overridden variable names.

# Returns
A `Scene` object with default empty fields, ready to be populated.
"""
function Scene()
    Scene(Dict{String,Material}(), World(), nothing, Dict{String,Float64}(), Set{String}())
end


# ─────────────────────────────────────────────────────────────
# Expect Token
#
# In our grammar, it is often the case that a symbol, identifier, 
# or keyword is mandatory at some point in the language. 
# It is handy to implement functions to handle the error condition 
# where the token is of an unexpected type.
# ─────────────────────────────────────────────────────────────

"Read a token from the stream and check that it matches 'symbol'."
function expect_symbol(instream::InputStream, symbol::AbstractString)
    token = read_token(instream)
    if !(isa(token, SymbolToken)) || token.symbol != symbol
        throw(GrammarError(token.location, "expected $symbol but found $token"))
    end
    return token.symbol
end

"""
Reads a token from the input stream and returns its numeric value.

Accepts
- a `LiteralNumberToken`;
- a `IdentifierToken` matching a variable in `scene.float_variables`.  
"""
function expect_number(instream::InputStream, scene::Scene)
    token = read_token(instream)
    if isa(token, LiteralNumberToken)
        return token.number
    elseif isa(token, IdentifierToken)
        variable_name = token.identifier
        if haskey(scene.float_variables, variable_name)
            return scene.float_variables[variable_name]
        else
            throw(GrammarError(token.location, "undefined $token"))
        end
    else 
        throw(GrammarError(token.location, "expected a number but found $token"))
    end
    return token.number
end

"Read a token from the stream and check that it is a String, returning a String."
function expect_string(instream::InputStream)
    token = read_token(instream)
    if !(isa(token, LiteralString))
        throw(GrammarError(token.location, "expected a string but found $token"))
    end
    return token.string
end

"Read a token from the stream and check that it is an 'identifier', returning a String."
function expect_identifier(instream::InputStream)
    token = read_token(instream)
    if !(isa(token, IdentifierToken))
        throw(GrammarError(token.location, "expected an identifier but found $token"))
    end
    return token.identifier
end

"Read a token form the stream and check that it is one of the keywords in the given list of keywords."
function expect_keywords(instream::InputStream, keywords::Vector{KeywordEnum})
    token = read_token(instream)

    if !(isa(token, KeywordToken))
        throw(GrammarError(token.location, "expected a keyword instead of $token"))
    end

    if !(token.keyword in keywords)
        # Convert keywords vector to a vector of strings for display
        expected = join(string.(keywords), ", ")
        throw(
            GrammarError(
                token.location,
                "expected one of the keywords {$(expected)} but found $token"
            ),
        )
    end
    return token.keyword
end


# ─────────────────────────────────────────────────────────────
# Scene Parser for RayTracer
#
# Functions for parsing scene description files in RayTracer.
# Includes parsing of vectors, colors, pigments, materials,
# transformations, shapes, cameras, and variables.
#
# The top-level function is `parse_scene` which processes the
# entire scene file and constructs a `Scene` object.
# ─────────────────────────────────────────────────────────────

"""
Parse a vector: `[x, y, z]` where x, y, z are numbers.

Returns a `Vec`.
"""
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

"""
Parse a color: `<r, g, b>` where r, g, b are numbers.

Returns a `RGB{Float32}`.
"""
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
Parse a pigment expression:

- `uniform(<r, g, b>)`
- `checkered(<r, g, b>, <r, g, b>, number)`
- `image("filename")` (supports `.pfm`, `.jpg`, `.jpeg`, `.png`, `.tiff`, `.tif`)

Returns a pigment type.
"""
function parse_pigment(instream::InputStream, scene::Scene)
    keyword = expect_keywords(instream, [IMAGE, UNIFORM, CHECKERED])
    expect_symbol(instream, "(")
    if keyword == UNIFORM
        color = parse_color(instream, scene)
        pigment = UniformPigment(color)
    elseif keyword == CHECKERED
        color1 = parse_color(instream, scene)
        expect_symbol(instream, ",")
        color2 = parse_color(instream, scene)
        expect_symbol(instream, ",")
        number = expect_number(instream, scene)
        pigment = CheckeredPigment(color1, color2, number)
    elseif keyword == IMAGE
        filename = expect_string(instream)
        if endswith(lowercase(filename), ".pfm")
            # .pfm image: ready to use
            pigment = ImagePigment(read_pfm_image(filename))
        elseif any(
            ext -> endswith(lowercase(filename), ext),
            SUPPORTED_EXTS,
        )
            # not .pfm image requires to be converted in .pfm
            pigment = ImagePigment(read_ldr_image(filename))
        else
            throw(
                GrammarError(
                    instream.location,
                    "Unexpected image format, plese use .pfm, .jpg, .tif, or .png",
                ),
            )
        end
    else
        throw(GrammarError(instream.location, "Invalid pigment keyword"))
    end
    expect_symbol(instream, ")")
    return pigment
end

"""
Parse a BRDF expression:

- `diffuse(pigment)`
- `specular(pigment)`

Returns a BRDF.
"""
function parse_brdf(instream::InputStream, scene::Scene)
    brdf = expect_keywords(instream, [DIFFUSE, SPECULAR])
    expect_symbol(instream, "(")
    pigment = parse_pigment(instream, scene)
    expect_symbol(instream, ")")
    if brdf == DIFFUSE
        return DiffuseBRDF(pigment)
    elseif brdf == SPECULAR
        return SpecularBRDF(pigment)
    else
        throw(GrammarError(instream.location, "Invalid BRDF keyword"))
    end
end


"""
Parse a material:

`material_name(brdf, emitted_radiance)`

Returns material identifier and `Material`.
"""
function parse_material(instream::InputStream, scene::Scene)
    mat_identifier = expect_identifier(instream)
    expect_symbol(instream, "(")
    brdf = parse_brdf(instream, scene)
    expect_symbol(instream, ",")
    emitted_radiance = parse_pigment(instream, scene)
    expect_symbol(instream, ")")
    return mat_identifier, Material(brdf, emitted_radiance)
end

"""
Parse one or more transformations:

- `identity`
- `translation([x, y, z])`
- `rotation_x(angle)`
- `rotation_y(angle)`
- `rotation_z(angle)`
- `scaling(x, y, z)`

Composed with `*`.

Returns a `Transformation`.
"""
function parse_transformation(instream::InputStream, scene::Scene)
    result = Transformation()
    while true
        transformation = expect_keywords(
            instream,
            [IDENTITY, TRANSLATION, ROTATION_X, ROTATION_Y, ROTATION_Z, SCALING],
        )
        if transformation == IDENTITY
            # Do nothing

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
            result *= scaling(x, y, z)

        else
            throw(GrammarError(instream.location, "invalid transformation keyword"))
        end

        # Transformations can be composed using "*".
        # Check if the next token is not "*" break the cycle and return the result.
        next_token = read_token(instream)
        if !(isa(next_token, SymbolToken)) || next_token.symbol != "*"
            # Put back the token
            unread_token(instream, next_token)
            break
        end
    end
    return result
end

"""
Parse a sphere:

`sphere(material_name, transformation)`

Returns a `Sphere`.
"""
function parse_sphere(instream::InputStream, scene::Scene)
    expect_symbol(instream, "(")
    material_name = expect_identifier(instream)
    if !haskey(scene.materials, material_name)
        throw(GrammarError(instream.location, "unknown material `$material_name`"))
    end
    expect_symbol(instream, ",")
    transformation = parse_transformation(instream, scene)
    expect_symbol(instream, ")")
    return Sphere(transformation, scene.materials[material_name])
end

"""
Parse a plane:

`plane(material_name, transformation)`

Returns a `Plane`.
"""
function parse_plane(instream::InputStream, scene::Scene)
    expect_symbol(instream, "(")
    material_name = expect_identifier(instream)
    if !haskey(scene.materials, material_name)
        throw(GrammarError(instream.location, "unknown material `$material_name`"))
    end
    expect_symbol(instream, ",")
    transformation = parse_transformation(instream, scene)
    expect_symbol(instream, ")")
    return Plane(transformation, scene.materials[material_name])
end

"""
Parse a camera:

- `camera(perspective, transformation, aspect_ratio, distance)`
- `camera(orthogonal, transformation, aspect_ratio)`

Returns a camera object.
"""
function parse_camera(instream::InputStream, scene::Scene)
    expect_symbol(instream, "(")
    cam = expect_keywords(instream, [PERSPECTIVE, ORTHOGONAL])
    expect_symbol(instream, ",")
    transformation = parse_transformation(instream, scene)
    expect_symbol(instream, ",")
    aspect_ratio = expect_number(instream, scene)
    if cam == PERSPECTIVE
        expect_symbol(instream, ",")
        distance = expect_number(instream, scene)
        camera = PerspectiveCamera(distance, aspect_ratio, transformation)
    else
        camera = OrthogonalCamera(aspect_ratio, transformation)
    end
    expect_symbol(instream, ")")
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
function parse_scene(instream::InputStream; variables = Dict{String,AbstractFloat}())
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

    while true

        token = read_token(instream)

        # End of file
        isnothing(token) && break


        # The first token of each construct must be a keyword, either a definition of var or a creation of object
        #       (e.g., FLOAT, MATERIAL, SPHERE, etc.)
        # Note: using 'expect_keywords' would require first read the token and check if reached end of file, 
        #       then unread_token and then use expect_keywords; this is simpler and clearer:
        if !(isa(token, KeywordToken))
            throw(GrammarError(token.location, "expected a keyword instead of $token"))
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
                    throw(GrammarError(var_loc, "variable $var_name cannot be redefined"))
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
            !isnothing(scene.camera) && throw(
                GrammarError(token.location, "you cannot define more than one camera"),
            )
            scene.camera = parse_camera(instream, scene)
        else
            # Raise an error for any unexpected keyword
            throw(GrammarError(token.location, "unexpected keyword $token"))
        end
    end
    return scene
end
