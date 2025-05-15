abstract type Pigment end

abstract type BRDF end

struct UniformPigment <: Pigment
    color::ColorTypes.RGB{Float32}
end

# TBD
# struct ImagePigment <: Pigment
#     image::HdrImage
# end

struct DiffuseBRDF <: BRDF
    pigm::Pigment
    reflectance::AbstractFloat
end

struct Material
    brdf::BRDF
    emitted_radiance::Pigment
end

function get_color(pigm::UniformPigment, uv::Vec2D)
    return pigm.color
end


function eval(brdf::DiffuseBRDF, n::Normal, in_dir::Vec, out_dir::Vec, uv::Vec2D)
    return brdf.pigment.get_color(uv) * (brdf.reflectance / π)
end