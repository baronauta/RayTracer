# ─────────────────────────────────────────────────────────────
# Pigment struct and functions
# ─────────────────────────────────────────────────────────────
abstract type Pigment end

# UniformPigment
struct UniformPigment <: Pigment
    color::ColorTypes.RGB{Float32}
end

function get_color(pigm::UniformPigment, uv::Vec2D)
    return pigm.color
end

# CheckeredPigment
struct CheckeredPigment <: Pigment
    color1::ColorTypes.RGB{Float32}
    color2::ColorTypes.RGB{Float32}
    squares_per_unit::Integer
end

function get_color(pigm::CheckeredPigment, uv::Vec2D)
    x = floor(Int, uv.u * pigm.squares_per_unit)
    y = floor(Int, uv.v * pigm.squares_per_unit)

    if iseven(x) == iseven(y)
        return pigm.color1
    else
        return pigm.color2
    end
end

# ImagePigment

struct ImagePigment <: Pigment
    img::HdrImage
end

# ⚠️ problem of overlapping last 2 col and row in the sphere (or any shape that u,v are [0,1] and not [0,1))
function get_color(pigm::ImagePigment, uv::Vec2D)
    # here i need to map a u-v coordinate on col-row in image. 
    # u,v ∈ [0,1], col, row ∈ [1,width],[1,height]
    # need to scale coordinates, then shift domain, then exclude over top bound on col/row
    col = clamp(Int(floor(uv.u * pigm.img.width)) + 1, 1, pigm.img.width)
    row = clamp(Int(floor(uv.v * pigm.img.height)) + 1, 1, pigm.img.height)
    get_pixel(pigm.img, col, row)
end

# ─────────────────────────────────────────────────────────────
# BRDF struct and functions
# ─────────────────────────────────────────────────────────────

abstract type BRDF end

struct DiffuseBRDF <: BRDF
    pigm::Pigment
    reflectance::AbstractFloat
end

function DiffuseBRDF()
    pigm = UniformPigment(WHITE)
    reflectance = 1.0
    DiffuseBRDF(pigm, reflectance)
end

struct Material
    brdf::BRDF
    emitted_radiance::Pigment
end

function Material()
    brdf = DiffuseBRDF()
    emitted_radiance = UniformPigment(GRAY)
    Material(brdf, emitted_radiance)
end

function eval(brdf::DiffuseBRDF, n::Normal, in_dir::Vec, out_dir::Vec, uv::Vec2D)
    return brdf.pigment.get_color(uv) * (brdf.reflectance / π)
end