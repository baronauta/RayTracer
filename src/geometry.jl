"A 3D point with coordinates `(x, y, z)`."
struct Point{T<:AbstractFloat}
    # `T <: AbstractFloat` ensures (x, y, z) share the same floating-point type, 
    # allowing precision control (e.g., Float32 vs Float64).
    x::T
    y::T
    z::T
end

"A 3D vector with components `(x, y, z)`."
struct Vec{T<:AbstractFloat}
    x::T
    y::T
    z::T
end

"""
A 2D vector with components `(u, v)` used for surface parameterization.
"""
struct Vec2D{T<:AbstractFloat}
    u::T
    v::T
end

"A 3D vector, orthogonal to a surface, with components `(x, y, z)`."
struct Normal{T<:AbstractFloat}
    x::T
    y::T
    z::T
end

const VEC_X = Vec(1.0, 0.0, 0.0)
const VEC_Y = Vec(0.0, 1.0, 0.0)
const VEC_Z = Vec(0.0, 0.0, 1.0)

"Display a `Point`."
function Base.show(io::IO, ::MIME"text/plain", p::Point)
    print(io, "Point(x=$(p.x), y=$(p.y), z=$(p.z))")
end

"Display a `Vec`."
function Base.show(io::IO, ::MIME"text/plain", v::Vec)
    print(io, "Vec(x=$(v.x), y=$(v.y), z=$(v.z))")
end

"Display a `Normal`."
function Base.show(io::IO, ::MIME"text/plain", n::Normal)
    print(io, "Point(x=$(n.x), y=$(n.y), z=$(n.z))")
end

"Check if two `Point`s are approximately equal."
function ≈(p::Point, q::Point; rtol=1e-5, atol=1e-5)
    return isapprox(p.x, q.x, rtol=rtol, atol=atol) &&
           isapprox(p.y, q.y, rtol=rtol, atol=atol) &&
           isapprox(p.z, q.z, rtol=rtol, atol=atol)
end

"Check if two `Vec`s are approximately equal."
function ≈(v::Vec, u::Vec; rtol=1e-5, atol=1e-5)
    return isapprox(v.x, u.x, rtol=rtol, atol=atol) &&
           isapprox(v.y, u.y, rtol=rtol, atol=atol) &&
           isapprox(v.z, u.z, rtol=rtol, atol=atol)
end

"Check if two `Vec2D`s are approximately equal."
function ≈(a::Vec2D, b::Vec2D; rtol=1e-5, atol=1e-5)
    return isapprox(a.u, b.u, rtol=rtol, atol=atol) &&
           isapprox(a.v, b.v, rtol=rtol, atol=atol)
end

"Check if two `Normal`s are approximately equal."
function ≈(n::Normal, m::Normal; rtol=1e-5, atol=1e-5)
    return isapprox(n.x, m.x, rtol=rtol, atol=atol) &&
           isapprox(n.y, m.y, rtol=rtol, atol=atol) &&
           isapprox(n.z, m.z, rtol=rtol, atol=atol)
end

"Add two `Vec` instances, returning a new `Vec`."
function +(v::Vec, u::Vec)
    Vec(v.x + u.x, v.y + u.y, v.z + u.z)
end

"Add a `Vec` to a `Point`, returning a new `Point`."
function +(p::Point, v::Vec)
    Point(p.x + v.x, p.y + v.y, p.z + v.z)
end

"Subtract one `Vec` from another, returning a new `Vec`."
function -(v::Vec, u::Vec)
    Vec(v.x - u.x, v.y - u.y, v.z - u.z)
end

"Subtract one `Point` from another, returning the resulting `Vec`."
function -(p::Point, q::Point)
    Vec(p.x - q.x, p.y - q.y, p.z - q.z)
end

"Subtract a `Vec` from a `Point`, returning a new `Point`."
function -(p::Point, v::Vec)
    Point(p.x - v.x, p.y - v.y, p.z - v.z)
end

"Multiply a `Vec` by a scalar, returning a new `Vec`."
function *(v::Vec, scalar::Real)
    return Vec(scalar * v.x, scalar * v.y, scalar * v.z)
end

"Multiply a scalar by a `Vec`, returning a new `Vec`."
function *(scalar::Real, v::Vec)
    return *(v, scalar)
end

"Multiply a `Normal` by a scalar, returning a new `Normal`."
function *(n::Normal, scalar::Real)
    return Normal(scalar * n.x, scalar * n.y, scalar * n.z)
end

"Multiply a scalar by a `Normal`, returning a new `Normal`."
function *(scalar::Real, n::Normal)
    return *(n, scalar)
end

"Negate a `Vec` or `Normal`, returning the vector multiplied by -1."
function -(v::Union{Vec, Normal})
    return (-1) * v
end

"Compute the dot product of two vectors, either `Vec` or `Normal`."
function dot(v::Union{Vec,Normal}, u::Union{Vec,Normal})
    return v.x * u.x + v.y * u.y + v.z * u.z
end

"Compute the cross product of two `Vec` instances, returning a new `Vec`."
function cross(v::Vec, u::Vec)
    return Vec(v.y * u.z - v.z * u.y, v.z * u.x - v.x * u.z, v.x * u.y - v.y * u.x)
end

"Compute the cross product of a `Vec` and a `Normal`, returning a `Vec`."
function cross(v::Vec, n::Normal)
    return Vec(v.y * n.z - v.z * n.y, v.z * n.x - v.x * n.z, v.x * n.y - v.y * n.x)
end

"Compute the cross product of a `Normal` and a `Vec`, returning a `Vec`."
function cross(n::Normal, v::Vec)
    # ( v × u ) = -( u × v )
    return -1 * cross(v, n)
end

"Compute the cross product of two `Normal` instances, returning a new `Normal`."
function cross(n::Normal, m::Normal)
    return Normal(n.y * m.z - n.z * m.y, n.z * m.x - n.x * m.z, n.x * m.y - n.y * m.x)
end

"""
Compute the squared norm of a vector (`Vec` or `Normal`),
i.e., v.x² + v.y² + v.z².
"""
function squared_norm(v::Union{Vec,Normal})
    return v.x^2 + v.y^2 + v.z^2
end

"""
Compute the norm (magnitude) of a vector (`Vec` or `Normal`),
i.e., √(v.x² + v.y² + v.z²).
"""
function norm(v::Union{Vec,Normal})
    sqrt(squared_norm(v))
end

"""
Normalize a vector (`Vec` or `Normal`), returning a unit vector in the same direction,
i.e., v → v / ||v||.
"""
function normalize(v::Union{Vec, Normal})
    n = norm(v)
    return typeof(v)(v.x / n, v.y / n, v.z / n)
end

"Convert a `Vec` into a `Normal`."
function vec_to_normal(v::Vec)
    Normal(v.x, v.y, v.z)
end

"Convert a `Point` into a `Vec`."
function point_to_vec(p::Point)
    return Vec(p.x, p.y, p.z)
end

"""
    onb_from_z(n::Union{Vec, Normal})

Compute an orthonormal basis given a normalized vector `n`.
Returns three perpendicular unit vectors `(e1, e2, n)`.
Uses the algorithm by Duff et al. (2017).
"""
function onb_from_z(n::Union{Vec, Normal})
    # The algorithm here used was proposed by Duff et al. in 2017.
    sign = copysign(1.0, n.z)
    a = -1.0 / (sign + n.z)
    b = n.x * n.y * a

    e1 = Vec(1.0 + sign * n.x * n.x * a, sign * b, -sign * n.x)
    e2 = Vec(b, sign + n.y * n.y * a, -n.y)

    return e1, e2, Vec(n.x, n.y, n.z)
end