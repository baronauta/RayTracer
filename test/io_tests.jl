#! format: off
# This is the content of "reference_le.pfm" (little-endian file)
LE_REFERENCE_BYTES = UInt8[
    0x50, 0x46, 0x0a, 0x33, 0x20, 0x32, 0x0a, 0x2d, 0x31, 0x2e, 0x30, 0x0a,
    0x00, 0x00, 0xc8, 0x42, 0x00, 0x00, 0x48, 0x43, 0x00, 0x00, 0x96, 0x43,
    0x00, 0x00, 0xc8, 0x43, 0x00, 0x00, 0xfa, 0x43, 0x00, 0x00, 0x16, 0x44,
    0x00, 0x00, 0x2f, 0x44, 0x00, 0x00, 0x48, 0x44, 0x00, 0x00, 0x61, 0x44,
    0x00, 0x00, 0x20, 0x41, 0x00, 0x00, 0xa0, 0x41, 0x00, 0x00, 0xf0, 0x41,
    0x00, 0x00, 0x20, 0x42, 0x00, 0x00, 0x48, 0x42, 0x00, 0x00, 0x70, 0x42,
    0x00, 0x00, 0x8c, 0x42, 0x00, 0x00, 0xa0, 0x42, 0x00, 0x00, 0xb4, 0x42
]
# This is the content of "reference_be.pfm" (big-endian file)
BE_REFERENCE_BYTES = UInt8[
    0x50, 0x46, 0x0a, 0x33, 0x20, 0x32, 0x0a, 0x31, 0x2e, 0x30, 0x0a, 0x42,
    0xc8, 0x00, 0x00, 0x43, 0x48, 0x00, 0x00, 0x43, 0x96, 0x00, 0x00, 0x43,
    0xc8, 0x00, 0x00, 0x43, 0xfa, 0x00, 0x00, 0x44, 0x16, 0x00, 0x00, 0x44,
    0x2f, 0x00, 0x00, 0x44, 0x48, 0x00, 0x00, 0x44, 0x61, 0x00, 0x00, 0x41,
    0x20, 0x00, 0x00, 0x41, 0xa0, 0x00, 0x00, 0x41, 0xf0, 0x00, 0x00, 0x42,
    0x20, 0x00, 0x00, 0x42, 0x48, 0x00, 0x00, 0x42, 0x70, 0x00, 0x00, 0x42,
    0x8c, 0x00, 0x00, 0x42, 0xa0, 0x00, 0x00, 0x42, 0xb4, 0x00, 0x00
]
#! format: on

@testset "I/O-Read" begin
    width = 128
    height = 256
    s1 = "$width $height"
    @test (width, height) == RayTracer._parse_img_size(s1)
    be = "+1.0" # big-endian
    @test RayTracer._parse_endianness(be) == 1.0
    le = "-1.0" # little-endian
    @test RayTracer._parse_endianness(le) == -1.0

    for reference_bytes in [LE_REFERENCE_BYTES, BE_REFERENCE_BYTES]
        stream = IOBuffer(reference_bytes)
        img = RayTracer.read_pfm_image(stream)
        @test RayTracer.get_pixel(img, 1, 1) ≈ (RGB(1.0e1, 2.0e1, 3.0e1))
        @test RayTracer.get_pixel(img, 2, 1) ≈ (RGB(4.0e1, 5.0e1, 6.0e1))
        @test RayTracer.get_pixel(img, 3, 1) ≈ (RGB(7.0e1, 8.0e1, 9.0e1))
        @test RayTracer.get_pixel(img, 1, 2) ≈ (RGB(1.0e2, 2.0e2, 3.0e2))
        @test RayTracer.get_pixel(img, 2, 2) ≈ (RGB(4.0e2, 5.0e2, 6.0e2))
        @test RayTracer.get_pixel(img, 3, 2) ≈ (RGB(7.0e2, 8.0e2, 9.0e2))
    end
end

@testset "I/O-Write" begin
    stream = IOBuffer(LE_REFERENCE_BYTES)
    img = RayTracer.read_pfm_image(stream)
    buf = IOBuffer()
    write(buf, img)
    contents = take!(buf)
    if IS_LITTLE_ENDIAN
        @test contents == LE_REFERENCE_BYTES
    else
        @test contents == BE_REFERENCE_BYTES
    end
    write(buf, img, endianness = 1.0)
    contents = take!(buf)
    @test contents == BE_REFERENCE_BYTES
end

@testset "I/O from actual file" begin
    stream = IOBuffer(LE_REFERENCE_BYTES)
    img = RayTracer.read_pfm_image(stream)
    write("test.PFM", img)
    img_from_file = RayTracer.read_pfm_image("test.PFM")
    @test RayTracer.get_pixel(img_from_file, 1, 1) ≈ RayTracer.get_pixel(img, 1, 1)
    @test RayTracer.get_pixel(img_from_file, 2, 1) ≈ RayTracer.get_pixel(img, 2, 1)
    @test RayTracer.get_pixel(img_from_file, 3, 1) ≈ RayTracer.get_pixel(img, 3, 1)
    @test RayTracer.get_pixel(img_from_file, 1, 2) ≈ RayTracer.get_pixel(img, 1, 2)
    @test RayTracer.get_pixel(img_from_file, 2, 2) ≈ RayTracer.get_pixel(img, 2, 2)
    @test RayTracer.get_pixel(img_from_file, 3, 2) ≈ RayTracer.get_pixel(img, 3, 2)
    rm("test.PFM")
end
