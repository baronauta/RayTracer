# Double quotes " for String, single quotes ' for Char
const WHITESPACE = [' ', '\t', '\n', '\r']
const COMMENT = '#'
    
abstract type Token end

"Holds the location of a character in the source code."
mutable struct SourceLocation
    filename::AbstractString
    line_num::Integer
    col_num::Integer
end

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
end

"Creates a new `InputStream` from an `IO` object and filename."
function InputStream(io::IO, filename::AbstractString; tab=4)
    # Initialize with line number and column number equal to 1
    location = SourceLocation(filename, 1, 1)
    # At the beginning saved_location is equal to location,
    # and there are no saved character.
    InputStream(io, location, nothing, location, tab)
end

"Given a character `ch`, in-place update of the position in `InputStream`."
function _update_pos!(instream::InputStream, ch::Union{AbstractChar, Nothing})
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
    if isnothing(instream.saved_char)
        instream.saved_char = ch
        instream.location = deepcopy(instream.saved_location)
    end
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

struct Keyword <: Token
    location::SourceLocation
end

struct Identifier <: Token
    location::SourceLocation
end

struct LiteralString <: Token
    location::SourceLocation
end

struct LiteralNumber <: Token
    location::SourceLocation
end

struct LexerSymbol <: Token
    location::SourceLocation
end

struct StopToken <: Token
    location::SourceLocation
end


