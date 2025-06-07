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


# --- Abstract types ---
abstract type Token end


# --- Constants ---
# Double quotes " for String, single quotes ' for Char
const WHITESPACE = [' ', '\t', '\n', '\r']
const COMMENT = '#'
const SYMBOLS = "()<>[],*"
const NUMBERS = "0123456789eE.+-"

# Enumeration of all the possible keywords recognized by the lexer.
# @enum provides a simpler and more robust solution than a list of constants. 
# Then use a dictionary to map strings to keywords.
# For clarity keywords are in capital letters.
@enum KeywordEnum begin
    NEW
    MATERIAL    
    PLANE    
    SPHERE    
    DIFFUSE    
    SPECULAR    
    UNIFORM    
    CHECKERED    
    IMAGE    
    IDENTITY
    TRANSLATION
    ROTATION_X
    ROTATION_Y
    ROTATION_Z
    SCALING
    CAMERA
    ORTHOGONAL
    PERSPECTIVE
    FLOAT
end

const KEYWORDS = Dict(
    "new" => NEW,
    "material" => MATERIAL,
    "plane" => PLANE,
    "sphere" => SPHERE,
    "diffuse" => DIFFUSE,
    "specular" => SPECULAR,
    "uniform" => UNIFORM,
    "checkered" => CHECKERED,
    "image" => IMAGE,
    "identity" => IDENTITY,
    "translation" => TRANSLATION,
    "rotation_x" => ROTATION_X,
    "rotation_y" => ROTATION_Y,
    "rotation_z" => ROTATION_Z,
    "scaling" => SCALING,
    "camera" => CAMERA,
    "orthogonal" => ORTHOGONAL,
    "perspective" => PERSPECTIVE,
    "float" => FLOAT,
)


# --- Source location ---
"Holds the location of a character in the source code."
mutable struct SourceLocation
    filename::String
    line_num::Integer
    col_num::Integer
end

"Exception to throw for reporting error while parsing scene file."
struct GrammarError <: Exception
    location::SourceLocation
    msg::String
end


# --- Tokens ---
"Token containing a recognized keyword."
struct KeywordToken <: Token
    location::SourceLocation
    keyword::KeywordEnum
end

"Token containing an identifier (i.e. variable name)."
struct IdentifierToken <: Token
    location::SourceLocation
    identifier::AbstractString
end

"Token containing a literal string."
struct LiteralString <: Token
    location::SourceLocation
    string::AbstractString
end

"Token containing a literal number."
struct LiteralNumber <: Token
    location::SourceLocation
    number::AbstractFloat
end

"Token containing a symbolic character (e.g., parentheses and operators)"
struct SymbolToken <: Token
    location::SourceLocation
    symbol::AbstractString
end


# --- InputStream ---
"""
Wraps an input stream with location tracking for lexing.

# Fields
- `stream::IO`: the actual input stream.
- `location::SourceLocation`: current location in the stream.
- `saved_char::Union{AbstractChar, Nothing}`: look-ahead character.
- `saved_location::SourceLocation`: location of the buffered character.
- `tabulation::Integer`: number of spaces per tab (used for column tracking).
"""
mutable struct InputStream
    stream::IO
    location::SourceLocation
    saved_char::Union{AbstractChar, Nothing}
    saved_location::SourceLocation
    tabulation::Integer
    saved_token::Union{Token, Nothing}
end

"Initialize `InputStream` from an `IO` type and a filename."
function InputStream(io::IO, filename::String; tab = 4)
    # Initialize with line number and column number equal to 1
    location = SourceLocation(filename, 1, 1)
    # At the beginning saved_location is equal to location,
    # and there are no saved character and saved token.
    InputStream(io, location, nothing, location, tab, nothing)
end


# ─────────────────────────────────────────────────────────────
# InputStream functions
# ─────────────────────────────────────────────────────────────

"Given a character `ch`, in-place update of the position in `InputStream`."
function _update_pos!(instream::InputStream, ch::Union{AbstractChar,Nothing})
    if isnothing(ch)
        return
    elseif ch == '\n'
        instream.location.line_num += 1
        instream.location.col_num = 1
    elseif ch == '\t'
        instream.location.col_num += instream.tabulation
    else
        instream.location.col_num += 1
    end
end

"""
Read a new character from the stream if `InpuStream.saved_char` is empty, otherwise
consider the saved char, returning a string. If it is the end of file return nothing.
"""
function _read_char!(instream::InputStream)
    # Fisrt look at saved_char: if there is a char read it, 
    # otherwise keep reading from the stream.
    if !isnothing(instream.saved_char)
        ch = instream.saved_char
        instream.saved_char = nothing
    else
        # Check that it is not the end of file
        if !eof(instream.stream)
            ch = read(instream.stream, Char)
        else
            return nothing
        end
    end
    # Save the current location: if the lexer finds a lexical error,
    # this is the location to be reported. Then update the position.
    instream.saved_location = deepcopy(instream.location)
    _update_pos!(instream, ch)
    return ch
end

"""
Pushes a character back into the input stream buffer.

This function implements a one-character look-ahead by storing the given character
in `saved_char` and restoring the location to `saved_location`. If a character
is already buffered, the function does nothing.
"""
function _unread_char!(instream::InputStream, ch::AbstractChar)
    # Only push back if no character is currently saved
    @assert isnothing(instream.saved_char)
    instream.saved_char = ch
    instream.location = deepcopy(instream.saved_location)
end

"Keep reading until a whitespace or a comment (begins with #) is found."
function skip_whitespaces_and_comments!(instream::InputStream)
    ch = _read_char!(instream)
    while ch in WHITESPACE || ch == '#'
        if ch == '#'
            # Skip the rest of the line
            while (ch = _read_char!(instream)) !== nothing && !(ch in ['\r', '\n'])
                # Do nothing, just consume characters
            end
        end
        ch = _read_char!(instream)
        if isnothing(ch) # end of file
            return
        end
    end

    # Put the non-whitespace character back
    _unread_char!(instream, ch)
end


# ─────────────────────────────────────────────────────────────
# Token reading functions
# ─────────────────────────────────────────────────────────────

function _parse_word_token(instream::InputStream, start_char::AbstractChar)
    token = string(start_char)
    while true
        ch = _read_char!(instream)
        if !(isletter(ch) || isdigit(ch) || ch == '_')
            _unread_char!(instream, ch)
            break
        end
        token = token * ch
    end
    # If the token is in the keyword list, return a Keyword token; otherwise, return an Identifier token
    haskey(KEYWORDS, token) ? (return KeywordToken(instream.location, KEYWORDS[token])) :
    (return IdentifierToken(instream.location, token))
end

function _parse_number_token(instream::InputStream, start_char::AbstractChar)
    token = string(start_char)

    while true
        ch = _read_char!(instream)
        if !occursin(ch, NUMBERS)
            _unread_char!(instream, ch)
            break
        end
        token *= ch
    end

    try
        return LiteralNumber(instream.location, parse(Float32, token))
    catch e
        if isa(e, ArgumentError)
            throw(
                GrammarError(
                    instream.location,
                    "'$token' is an invalid floating-point number",
                ),
            )
        else
            rethrow()
        end
    end
end


function _parse_string_token(instream::InputStream)
    token = ""
    while true
        # read the char and update token if not the end of string or eof 
        ch = _read_char!(instream)
        ch == '"' && break
        isnothing(ch) && throw(GrammarError(instream.location, "unterminated string"))
        token *= ch
    end
    return LiteralString(instream.location, token)
end

function read_token(instream::InputStream)
    if !isnothing(instream.saved_token)
        result = instream.saved_token
        instream.saved_token = nothing
        return result
    end
    # first skip whitespaces and comments
    skip_whitespaces_and_comments!(instream)
    # read first char and decide which token to return
    ch = _read_char!(instream)
    # if is eof return a "nothing token"
    isnothing(ch) && return nothing
    # token_location = deepcopy(instream.saved_location)

    # if symbol return symbol token
    occursin(ch, SYMBOLS) && return SymbolToken(instream.location, string(ch))

    # if string return LiteralString token
    ch == '"' && return _parse_string_token(instream)

    # if number return LiteralNumber token
    (isdigit(ch) || ch == '+' || ch == '-') && return _parse_number_token(instream, ch)

    # if alphabethic return KeywordToken or IdentifierToken
    (isletter(ch) || ch == '_') && return _parse_word_token(instream, ch)

    # if no condition is satisfied means that not interrupted with a return, so
    throw(GrammarError(instream.location, "Invalid character: $ch"))
end

function unread_token(instream::InputStream, token::Token)
    @assert isnothing(instream.saved_token)
    instream.saved_token = token
end
