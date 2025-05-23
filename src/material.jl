abstract type Pigment end

abstract type BRDF end

struct UniformPigment <: Pigment
    color::ColorTypes.RGB{Float32}
end

struct CheckeredPigment <: Pigment
    color1::ColorTypes.RGB{Float32}
    color2::ColorTypes.RGB{Float32}
    squares_per_unit::Integer
end

# TBD
# struct ImagePigment <: Pigment
#     image::HdrImage
# end

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

function get_color(pigm::UniformPigment, uv::Vec2D)
    return pigm.color
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

function eval(brdf::DiffuseBRDF, n::Normal, in_dir::Vec, out_dir::Vec, uv::Vec2D)
    return brdf.pigment.get_color(uv) * (brdf.reflectance / π)
end