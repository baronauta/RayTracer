# === Abstract Types ===
abstract type Pigment end
abstract type BRDF end

# === Pigments ===
"A pigment with a uniform RGB color."
struct UniformPigment <: Pigment
    color::ColorTypes.RGB{Float32}
end

"Returns the uniform color of the pigment."
function get_color(pigm::UniformPigment, uv::Vec2D)
    return pigm.color
end

"A pigment with a checkerboard pattern alternating between two colors."
struct CheckeredPigment <: Pigment
    color1::ColorTypes.RGB{Float32}
    color2::ColorTypes.RGB{Float32}
    squares_per_unit::Integer
end

"Returns the color at UV coordinate based on the checkered pattern."
function get_color(pigm::CheckeredPigment, uv::Vec2D)
    x = floor(Int, uv.u * pigm.squares_per_unit)
    y = floor(Int, uv.v * pigm.squares_per_unit)
    return iseven(x) == iseven(y) ? pigm.color1 : pigm.color2
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

# === BRDFs ===
"An ideal diffuse BRDF with a given pigment."
struct DiffuseBRDF <: BRDF
    pigm::Pigment
end

"Constructs a default `DiffuseBRDF` using a white uniform pigment."
function DiffuseBRDF()
    DiffuseBRDF(UniformPigment(WHITE))
end

"Calculate the value of the BRDF in a certain point."
function eval(brdf::DiffuseBRDF, n::Normal, in_dir::Vec, out_dir::Vec, uv::Vec2D)
    # an ideal diffuse BRDF, so the value is constant everyware
    return brdf.pigment.get_color(uv) / π
end

"""
    scatter_ray(brdf::DiffuseBRDF, pcg::PCG, incoming_dir::Vec, interaction_point::Point, normal::Normal, depth::Integer) -> Ray

Generates a secondary ray by sampling a random outgoing direction from a diffuse surface.
Given an incoming ray that hits a surface at a specific point with a given normal, this function 
samples a direction in the hemisphere around the normal and returns the corresponding scattered ray.
"""
function scatter_ray(
    brdf::DiffuseBRDF,
    pcg::PCG,
    incoming_dir::Vec,
    interaction_point::Point,
    normal::Normal,
    depth::Integer,
)
    # Construct an orthonormal basis (e1, e2, e3)
    # with e3 aligned to the surface normal.
    e1, e2, e3 = onb_from_z(normal)
    # Draw a random direction ω = (θ, ϕ) on hemisphere,
    # that is θ ∈ [0,π/2] and ϕ ∈ [0,2π], from the Phong distribution,
    # i.e. P(ω) = k cosθ where k is the normalization constant.
    # Sampling from P(θ, ϕ) = P(θ) P(ϕ|θ) is obtained by drawing a
    # a random value θ from the marginal PDF P(θ), then compute the
    # conditional PDF P(ϕ|θ) and draw a random value ϕ.
    # With X1 and X2 random number drawn from a uniform PDF in [0,1],
    # we match ther desired PDF by considering θ = arccos[√X1] and 
    # ϕ = 2πX2.
    cosθ_sq = random_float!(pcg) # cosθ = cos[arccos(√X1)] = √X1
    cosθ, sinθ = sqrt(cosθ_sq), sqrt(1.0 - cosθ_sq)
    ϕ = 2.0 * π * random_float!(pcg)
    # Return a ray with origin in the interaction point and direction ω.
    # The direction is computed in local space using spherical coordinates, 
    # then transformed into world space using the ONB.
    # Recall: in local spherical coordinates,
    #   x = sinθ * cosϕ   (aligned with e1)
    #   y = sinθ * sinϕ   (aligned with e2)
    #   z = cosθ          (aligned with e3, the surface normal)
    return Ray(
        interaction_point,
        e1 * sinθ * cos(ϕ) + e2 * sinθ * sin(ϕ) + e3 * cosθ,
        1.0e-3,
        typemax(typeof(interaction_point.x)),
        depth,
    )
end

"An ideal reflective BRDF with a given pigment and angle tolerance."
struct SpecularBRDF <: BRDF
    pigm::Pigment
    angle_tolerance::AbstractFloat
end

"Constructs a default `SpecularBRDF` using a white uniform pigment and default angle tolerance."
function SpecularBRDF()
    pigm = UniformPigment(WHITE)
    angle_tolerance = pi / 1800.0
    SpecularBRDF(pigm, angle_tolerance)
end

"Constructs a default `SpecularBRDF` using a angle tolerance."
function SpecularBRDF(pigm::Pigment)
    angle_tolerance = pi / 1800.0
    SpecularBRDF(pigm, angle_tolerance)
end

"Calculate the value of the BRDF in a certain point."
function eval(brdf::SpecularBRDF, n::Normal, in_dir::Vec, out_dir::Vec, uv::Vec2D)
    # an ideal Reflective BRDF, so the value is ≠ 0 only for the specular reflected angle θᵣ
    θᵢ = acos(dot(n, in_dir))
    θᵣ = acos(dot(n, out_dir))
    if abs(θᵢ - θᵣ) < brdf.angle_tolerance
        return get_color(brdf.pigment, uv)
    else
        return BLACK
    end
end

"""
    scatter_ray(brdf::SpecularBRDF, pcg::PCG, incoming_dir::Vec, interaction_point::Point, normal::Normal, depth::Integer) -> Ray

Generates a secondary ray by finding the only right reflected direction.
"""
function scatter_ray(
    brdf::SpecularBRDF,
    pcg::PCG,
    incoming_dir::Vec,
    interaction_point::Point,
    normal::Normal,
    depth::Integer,
)
    # no need to create random emisphere direction;
    # only one direction that obey the reflectance law is needed.
    #
    #                               ↑ n (2 times Ψ, inverted sign respect to Ψ)
    #    Ψ(original incident ray)   |
    #                             \ | / Ψ + n (reflected ray)
    #                              \|/
    #   ___(surface)________________o (interacion point)___________(surface)____

    Ψ = normalize(Vec(incoming_dir.x, incoming_dir.y, incoming_dir.z))
    _n = normalize(normal)
    dot_prod = dot(Ψ, _n)
    n = RayTracer.normal_to_vec((-2) * _n * dot_prod)
    Ψᵣ = Ψ + n

    return Ray(interaction_point, Ψᵣ, 1.0e-3, typemax(typeof(interaction_point.x)), depth)
end


# === Material ===
"Material with surface caracteristics (BRDF) and emitted light (radiance)."
struct Material
    brdf::BRDF
    emitted_radiance::Pigment
end

"Construct a default Material with diffuse BRDF and no emission."
function Material()
    brdf = DiffuseBRDF()
    emitted_radiance = UniformPigment(BLACK)
    Material(brdf, emitted_radiance)
end

"Construct a Material with given BRDF and no emission."
function Material(brdf::BRDF)
    emitted_radiance = UniformPigment(BLACK)
    Material(brdf, emitted_radiance)
end

"Construct a Material with given emitted radiance and diffuse BRDF (uniform black pigment)."
function Material(emitted_radiance::Pigment)
    brdf = DiffuseBRDF(UniformPigment(BLACK))
    Material(brdf, emitted_radiance)
end
