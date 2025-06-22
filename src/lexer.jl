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
    TRANSFORMATION
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
    MOTION
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
    "transformation" => TRANSFORMATION,
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
    "motion" => MOTION,
)


# --- Source location ---
"Holds the location of a character in the source code."
mutable struct SourceLocation
    filename::String
    line_num::Integer
    col_num::Integer
end

"Show SourceLocation in the format filename:line:column (e.g. file.txt:3:45)."
function Base.show(io::IO, s::SourceLocation)
    print(io, "$(s.filename):$(s.line_num):$(s.col_num)")
end

"Exception to throw for reporting error while parsing scene file."
struct GrammarError <: CustomException
    location::SourceLocation
    msg::String
end

"Show GrammarError"
function Base.show(io::IO, err::GrammarError)
    red_bold = Crayons.Crayon(foreground=:red, bold=true)
    cyan = Crayons.Crayon(foreground=:cyan)
    yellow_bold = Crayons.Crayon(foreground=:yellow, bold=true)
    
    print(io,
        red_bold("GrammarError "),
        "at ",
        cyan(string(err.location)),
        ": ",
        yellow_bold(err.msg)
    )
end

# --- Tokens ---
"Token containing a recognized keyword"
struct KeywordToken <: Token
    location::SourceLocation
    keyword::KeywordEnum
end

"Show KeywordToken"
function Base.show(io::IO, tok::KeywordToken)
    print(io, "keyword $(tok.keyword)")
end


"Token containing an identifier (i.e. variable name)"
struct IdentifierToken <: Token
    location::SourceLocation
    identifier::AbstractString
end

"Show IdentifierToken"
function Base.show(io::IO, tok::IdentifierToken)
    print(io, "identifier \"$(tok.identifier)\"")
end

"Token containing a string"
struct StringToken <: Token
    location::SourceLocation
    string::AbstractString
end

"Show StringToken"
function Base.show(io::IO, tok::StringToken)
    print(io, "string \"$(tok.string)\"")
end

"Token containing a literal number"
struct LiteralNumberToken <: Token
    location::SourceLocation
    number::AbstractFloat
end

"Show LiteralNumberToken"
function Base.show(io::IO, tok::LiteralNumberToken)
    print(io, "number $(tok.number)")
end

"Token containing a symbolic character (e.g., parentheses and operators)"
struct SymbolToken <: Token
    location::SourceLocation
    symbol::AbstractString
end

"Show SymbolToken"
function Base.show(io::IO, tok::SymbolToken)
    print(io, "symbol \"$(tok.symbol)\"")
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
# Stream reading
#
# Functions for reading characters from the input stream one by one.
# These functions skip over whitespace and comments, while accurately
# tracking the current position (line and column) within the stream.
# ─────────────────────────────────────────────────────────────

"Given a character `ch`, update the position in `instream` in-place."
function _update_pos!(instream::InputStream, ch::Union{AbstractChar,Nothing})
    if isnothing(ch)
        # No position update is performed
        return
    elseif ch == '\n'
        # Newline: increment the line number and reset the column to 1
        instream.location.line_num += 1
        instream.location.col_num = 1
    elseif ch == '\t'
        # Tab: advance the column number by the configured tab width
        instream.location.col_num += instream.tabulation
    else
        # Char: increment the column number
        instream.location.col_num += 1
    end
end

"""
Read the next character from the input stream.

If `instream.saved_char` contains a character, consume and return it.
Otherwise, read a new character from the stream.

- Returns a single character as a `Char`.
- Returns `nothing` if the end of the file is reached.

Updates the saved location before updating the current position, so that
lexical errors can be reported accurately.
"""
function _read_char!(instream::InputStream)
    if !isnothing(instream.saved_char)
        # saved_char contains a char
        ch = instream.saved_char
        instream.saved_char = nothing
    else
        if eof(instream.stream)
            # end of file: return nothing
            return nothing
        else
            # read from the stream
            ch = read(instream.stream, Char)
        end
    end
    # Save the current location before advancing
    instream.saved_location = deepcopy(instream.location)
    _update_pos!(instream, ch)
    return ch
end

"""
Push a character back into the input stream buffer for one-character look-ahead.

- Stores the given character in `saved_char`.
- Restores the stream position to `saved_location`.
- Throws an assertion error if `saved_char` is already occupied.
"""
function _unread_char!(instream::InputStream, ch::AbstractChar)
    @assert isnothing(instream.saved_char) "Buffer already contains a saved character"
    instream.saved_char = ch
    instream.location = deepcopy(instream.saved_location)
end

"""
Skip all whitespace characters and comments in the input stream.

- Whitespace characters are defined by `WHITESPACE`.
- Comments start with `#` and continue until the end of the line.
- Reading stops at the first non-whitespace, non-comment character.
- The first such character is pushed back onto the stream for subsequent processing.
"""
function _skip_whitespaces_and_comments!(instream::InputStream)
    ch = _read_char!(instream)
    isnothing(ch) && return nothing
    while ch in WHITESPACE || ch == '#'
        if ch == '#'
            # Skip the end of the line
            while (ch = _read_char!(instream)) !== nothing && !(ch in ['\r', '\n'])
                # consume characters silently
            end
        end
        ch = _read_char!(instream)
        if isnothing(ch)
            # we used `nothing` to mark the eof
            return
        end
    end
    # Reading stops at the first non-whitespace, non-comment character.
    # The first such character is pushed back onto the stream for subsequent processing.
    _unread_char!(instream, ch)
end


# ─────────────────────────────────────────────────────────────
# Read Tokens
#
# Read and classify tokens from the input stream.
# ─────────────────────────────────────────────────────────────

"""
Parse a string token enclosed in double quotes.

Reads characters until the closing quote is found. Raises a `GrammarError`
if the string is not properly terminated.
"""
function _parse_string_token(instream::InputStream)
    token = ""
    while true
        # Read the char and update token if not the end of string or eof 
        ch = _read_char!(instream)
        if ch == '"'
            # Closing quote is found: parsed string is complete
            break
        end
        if isnothing(ch)
            # Reached eof, closing quote not found
            throw(GrammarError(instream.location, "unterminated string"))
        end
        token *= ch
    end
    return StringToken(instream.location, token)
end

"""
Parse a numeric token from the stream.

Accumulates digits (and optional sign) into a string and attempts to parse
a `Float32` from it. If parsing fails, raises a `GrammarError`.
"""
function _parse_number_token(instream::InputStream, start_char::AbstractChar)
    token = string(start_char)
    while true
        # Accumulates digits
        ch = _read_char!(instream)
        if !occursin(ch, NUMBERS)
            # Non-digit found: parsed number is complete
            _unread_char!(instream, ch)
            break
        end
        token *= ch
    end

    try
        # ⚠️ Possible bottleneck: why to define functions with AbstractFloat if we are able only to parse
        # float32?
        return LiteralNumberToken(instream.location, parse(Float64, token))
    catch e
        if isa(e, ArgumentError)
            throw(
                GrammarError(
                    instream.location,
                    "$token is an invalid floating-point number",
                ),
            )
        else
            rethrow()
        end
    end
end

"""
Parse an identifier or keyword token from the input stream.

Starting with `start_char`, this function accumulates a sequence of letters, digits,
and underscores into a token. If the token matches a known keyword, it returns a
`KeywordToken`; otherwise, it returns an `IdentifierToken`.
"""
function _parse_keyword_or_identifier(instream::InputStream, start_char::AbstractChar)
    token = start_char
    while true
        # Accumulate accepted char
        ch = _read_char!(instream)
        if !(isletter(ch) || isdigit(ch) || ch == '_')
            # Non valid char: parsed word is complete
            _unread_char!(instream, ch)
            break
        end
        token *= ch
    end
    if haskey(KEYWORDS, token)
        # If it is a KeywordToken it must be listed in the KEYWORDS dictionary
        return KeywordToken(instream.location, KEYWORDS[token])
    else
        return IdentifierToken(instream.location, token)
    end
end

"""
Read the next token from the stream.

Skips whitespace and comments, then reads and returns the appropriate token:
- `SymbolToken` for symbols
- `StringToken` for quoted strings
- `LiteralNumberToken` for numeric literals
- `KeywordToken` or `IdentifierToken` for words

Returns `nothing` at the end of the file.
"""
function read_token(instream::InputStream)
    if !isnothing(instream.saved_token)
        result = instream.saved_token
        instream.saved_token = nothing
        return result
    end

    _skip_whitespaces_and_comments!(instream)
    ch = _read_char!(instream)

    # End of file
    isnothing(ch) && return nothing

    # SymbolToken
    occursin(ch, SYMBOLS) && return SymbolToken(instream.location, string(ch))

    # StringToken
    ch == '"' && return _parse_string_token(instream)

    # LiteralNumberToken
    (isdigit(ch) || ch == '+' || ch == '-') && return _parse_number_token(instream, ch)

    # KeywordToken or IdentifierToken
    (isletter(ch) || ch == '_') && return _parse_keyword_or_identifier(instream, ch)

    # If no condition is satisfied
    throw(GrammarError(instream.location, "invalid character $ch"))
end

"Push a token back into the stream."
function unread_token(instream::InputStream, token::Token)
    @assert isnothing(instream.saved_token) "Cannot push back multiple tokens"
    instream.saved_token = token
end
