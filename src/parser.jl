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
    materials::Dict{string, Material}
    world::World
    camera::Union{Camera, Nothing}
end

"Read a token form the stream and check that it matches 'symbol'."
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
end

"Read a token form the stream and check that it matches 'number'."
function _expect_number(instream::InputStream, number::AbstractFloat)
    token = read_token(instream)
    if !(isa(token, LiteralNumber)) || token.number != number
        throw(
            GrammarError(
                token.location,
                "got '$token'  instead of '$number'",
            ),
        )
    end
end

"Read a token form the stream and check that it matches 'string'."
function _expect_string(instream::InputStream, string::AbstractString)
    token = read_token(instream)
    if !(isa(token, LiteralString)) || token.string != string
        throw(
            GrammarError(
                token.location,
                "got '$token'  instead of '$string'",
            ),
        )
    end
end

"Read a token form the stream and check that it matches 'identifier'."
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
end
