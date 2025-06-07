@testset "InputFile" begin
    instream = RayTracer.InputStream(IOBuffer("abc   \nd\nef"), "")

    # Check initial position
    @test instream.location.line_num == 1
    @test instream.location.col_num == 1

    # Start reading
    # Note: Char type are denoted with single quotes
    @test RayTracer._read_char!(instream) == 'a'
    @test instream.location.line_num == 1
    @test instream.location.col_num == 2

    # Force the use of _unread_char!
    RayTracer._unread_char!(instream, 'Z') # instream.location is restored to the saved_location
    @test instream.location.line_num == 1
    @test instream.location.col_num == 1

    # Next call of _read_char! should read the char in saved_char
    @test RayTracer._read_char!(instream) == 'Z'
    @test instream.location.line_num == 1
    @test instream.location.col_num == 2

    # Continue reading from the stream
    @test RayTracer._read_char!(instream) == 'b'
    @test instream.location.line_num == 1
    @test instream.location.col_num == 3
    @test RayTracer._read_char!(instream) == 'c'
    @test instream.location.line_num == 1
    @test instream.location.col_num == 4

    RayTracer._skip_whitespaces_and_comments!(instream)

    @test RayTracer._read_char!(instream) == 'd'
    @test instream.location.line_num == 2
    @test instream.location.col_num == 2

    @test RayTracer._read_char!(instream) == '\n'
    @test instream.location.line_num == 3
    @test instream.location.col_num == 1

    @test RayTracer._read_char!(instream) == 'e'
    @test instream.location.line_num == 3
    @test instream.location.col_num == 2

    @test RayTracer._read_char!(instream) == 'f'
    @test instream.location.line_num == 3
    @test instream.location.col_num == 3

    # End of file
    @test isnothing(RayTracer._read_char!(instream))
end

@testset "Token" begin
    function _test_keyword(token::Token, keyword::RayTracer.KeywordEnum)
        @test token isa RayTracer.KeywordToken
        @test token.keyword == keyword || println(
            "Token: $(token.keyword) at location: $(token.location) is not equal to keyword $keyword",
        )
    end
    function _test_identifier(token::Token, identifier::AbstractString)
        @test token isa RayTracer.IdentifierToken
        @test token.identifier == identifier || println(
            "Token: $(token.identifier) at location: $(token.location) is not equal to identifier $identifier",
        )
    end
    function _test_string(token::Token, string::AbstractString)
        @test token isa RayTracer.StringToken
        @test token.string == string || println(
            "Token: $(token.string) at location: $(token.location) is not equal to string $string",
        )
    end
    function _test_number(token::Token, number::AbstractFloat)
        @test token isa RayTracer.LiteralNumberToken
        @test token.number == number || println(
            "Token: $(token.number) at location: $(token.location) is not equal to number $number",
        )
    end
    function _test_symbol(token::Token, symbol::AbstractString)
        @test token isa RayTracer.SymbolToken
        @test token.symbol == symbol || println(
            "Token: $(token.symbol) at location: $(token.location) is not equal to symbol $symbol",
        )
    end

    stream = IOBuffer("""
                        # This is a comment
                        # This is another comment
                        new material sky_material(
                            diffuse(image("my file.pfm")),
                            <5.0, 500.0, 300.0>
                        ) # Comment at the end of the line
                    """)

    instream = RayTracer.InputStream(stream, "")
    _test_keyword(RayTracer.read_token(instream), RayTracer.NEW)
    _test_keyword(RayTracer.read_token(instream), RayTracer.MATERIAL)
    _test_identifier(RayTracer.read_token(instream), "sky_material")
    _test_symbol(RayTracer.read_token(instream), "(")
    _test_keyword(RayTracer.read_token(instream), RayTracer.DIFFUSE)
    _test_symbol(RayTracer.read_token(instream), "(")
    _test_keyword(RayTracer.read_token(instream), RayTracer.IMAGE)
    _test_symbol(RayTracer.read_token(instream), "(")
    _test_string(RayTracer.read_token(instream), "my file.pfm")
    _test_symbol(RayTracer.read_token(instream), ")")
    _test_symbol(RayTracer.read_token(instream), ")")
    _test_symbol(RayTracer.read_token(instream), ",")
    _test_symbol(RayTracer.read_token(instream), "<")
    _test_number(RayTracer.read_token(instream), 5.0)
    _test_symbol(RayTracer.read_token(instream), ",")
    _test_number(RayTracer.read_token(instream), 500.0)
    _test_symbol(RayTracer.read_token(instream), ",")
    _test_number(RayTracer.read_token(instream), 300.0)
    _test_symbol(RayTracer.read_token(instream), ">")
    _test_symbol(RayTracer.read_token(instream), ")")
end
