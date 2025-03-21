using RayTracer
using Test

import ColorTypes

@testset "Colors" begin
    c1 = ColorTypes.RGB{Float32}(0.1, 0.2, 0.3)
    c2 = ColorTypes.RGB{Float32}(0.4, 0.5, 0.6)
    @test c1 ≈ ColorTypes.RGB{Float32}(0.1, 0.2, 0.3)
    @test !(c1 ≈ c2)
    @test c1 + c2 ≈ ColorTypes.RGB{Float32}(0.5, 0.7, 0.9)
    @test 2 * c1 ≈ ColorTypes.RGB{Float32}(0.2, 0.4, 0.6)
    @test c1 * c2 ≈ ColorTypes.RGB{Float32}(0.04, 0.1, 0.18)
    @test RayTracer.color_to_string(c1) == "< r:0.1, g:0.2, b:0.3 >"
end

@testset "HdrImage" begin
    width = 9
    height = 6
    img = HdrImage(width, height)
    @test img.height == height
    @test img.width == width
    x = 7
    y = 5
    c = ColorTypes.RGB{Float32}(0.1, 0.2, 0.3)
    RayTracer.set_pixel!(img, x, y, c)
    @test img.pixels[y, x] ≈ c
    @test c ≈ RayTracer.get_pixel(img, x, y)
end

@testset "I/O-Read" begin
    # Unit tests
    width = 128
    height = 256
    s1 = "$width $height"
    @test (width, height) == RayTracer._parse_img_size(s1)
    be = "+1.0"
    le = "-1.0"
    @test RayTracer._parse_endianness(be) == 1.0
    @test RayTracer._parse_endianness(le) == -1.0
    # Integration test
    for filename in ["reference_be.pfm", "reference_le.pfm"]
        stream = open(filename, "r")
        img = RayTracer.read_pfm_image(stream)
        get_pixel(img, 1, 1) ≈ (ColorTypes.RGB{Float32}(1.0e1, 2.0e1, 3.0e1))
        get_pixel(img, 2, 1) ≈ (ColorTypes.RGB{Float32}(4.0e1, 5.0e1, 6.0e1))
        get_pixel(img, 3, 1) ≈ (ColorTypes.RGB{Float32}(7.0e1, 8.0e1, 9.0e1))
        get_pixel(img, 1, 2) ≈ (ColorTypes.RGB{Float32}(1.0e2, 2.0e2, 3.0e2))
        get_pixel(img, 2, 2) ≈ (ColorTypes.RGB{Float32}(4.0e2, 5.0e2, 6.0e2))
        get_pixel(img, 3, 2) ≈ (ColorTypes.RGB{Float32}(7.0e2, 8.0e2, 9.0e2))
    end
end

@testset "I/O-Write" begin
    # This is the content of "reference_le.pfm" (little-endian file)
    LE_REFERENCE_BYTES = UInt8[
        0x50,
        0x46,
        0x0a,
        0x33,
        0x20,
        0x32,
        0x0a,
        0x2d,
        0x31,
        0x2e,
        0x30,
        0x0a,
        0x00,
        0x00,
        0xc8,
        0x42,
        0x00,
        0x00,
        0x48,
        0x43,
        0x00,
        0x00,
        0x96,
        0x43,
        0x00,
        0x00,
        0xc8,
        0x43,
        0x00,
        0x00,
        0xfa,
        0x43,
        0x00,
        0x00,
        0x16,
        0x44,
        0x00,
        0x00,
        0x2f,
        0x44,
        0x00,
        0x00,
        0x48,
        0x44,
        0x00,
        0x00,
        0x61,
        0x44,
        0x00,
        0x00,
        0x20,
        0x41,
        0x00,
        0x00,
        0xa0,
        0x41,
        0x00,
        0x00,
        0xf0,
        0x41,
        0x00,
        0x00,
        0x20,
        0x42,
        0x00,
        0x00,
        0x48,
        0x42,
        0x00,
        0x00,
        0x70,
        0x42,
        0x00,
        0x00,
        0x8c,
        0x42,
        0x00,
        0x00,
        0xa0,
        0x42,
        0x00,
        0x00,
        0xb4,
        0x42,
    ]

    # This is the content of "reference_be.pfm" (big-endian file)
    BE_REFERENCE_BYTES = UInt8[
        0x50,
        0x46,
        0x0a,
        0x33,
        0x20,
        0x32,
        0x0a,
        0x31,
        0x2e,
        0x30,
        0x0a,
        0x42,
        0xc8,
        0x00,
        0x00,
        0x43,
        0x48,
        0x00,
        0x00,
        0x43,
        0x96,
        0x00,
        0x00,
        0x43,
        0xc8,
        0x00,
        0x00,
        0x43,
        0xfa,
        0x00,
        0x00,
        0x44,
        0x16,
        0x00,
        0x00,
        0x44,
        0x2f,
        0x00,
        0x00,
        0x44,
        0x48,
        0x00,
        0x00,
        0x44,
        0x61,
        0x00,
        0x00,
        0x41,
        0x20,
        0x00,
        0x00,
        0x41,
        0xa0,
        0x00,
        0x00,
        0x41,
        0xf0,
        0x00,
        0x00,
        0x42,
        0x20,
        0x00,
        0x00,
        0x42,
        0x48,
        0x00,
        0x00,
        0x42,
        0x70,
        0x00,
        0x00,
        0x42,
        0x8c,
        0x00,
        0x00,
        0x42,
        0xa0,
        0x00,
        0x00,
        0x42,
        0xb4,
        0x00,
        0x00,
    ]

    img = HdrImage(3, 2)
    set_pixel!(img, 1, 1, RayTracer.ColorTypes.RGB{Float32}(1.0e1, 2.0e1, 3.0e1))
    set_pixel!(img, 2, 1, RayTracer.ColorTypes.RGB{Float32}(4.0e1, 5.0e1, 6.0e1))
    set_pixel!(img, 3, 1, RayTracer.ColorTypes.RGB{Float32}(7.0e1, 8.0e1, 9.0e1))
    set_pixel!(img, 1, 2, RayTracer.ColorTypes.RGB{Float32}(1.0e2, 2.0e2, 3.0e2))
    set_pixel!(img, 2, 2, RayTracer.ColorTypes.RGB{Float32}(4.0e2, 5.0e2, 6.0e2))
    set_pixel!(img, 3, 2, RayTracer.ColorTypes.RGB{Float32}(7.0e2, 8.0e2, 9.0e2))

    buf = IOBuffer()
    RayTracer.write(buf, img, endianness = my_endian)
    contents = take!(buf)
    @test contents == LE_REFERENCE_BYTES

    write(buf, img)
    contents = take!(buf)
    @test contents == LE_REFERENCE_BYTES

    RayTracer.write(buf, img; endianness = 1.0)
    contents = take!(buf)
    @test contents == BE_REFERENCE_BYTES

    # test for exceptions (?)
    # ...

end
