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

    RayTracer.skip_whitespaces_and_comments!(instream)

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