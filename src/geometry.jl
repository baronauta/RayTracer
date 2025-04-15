import Base: +, -, *, ≈

# ─────────────────────────────────────────────────────────────
# Defining new types:
#   - Point
#   - Vec
#   - Normal
# ─────────────────────────────────────────────────────────────

"A 3D point with coordinates `(x, y, z)` of type `T`."
struct Point{T<:AbstractFloat}
    x::T
    y::T
    z::T
end

"A 3D vector with components `(x, y, z)` of type `T`."
struct Vec{T<:AbstractFloat}
    x::T
    y::T
    z::T
end

"A 3D vector, orthogonal to a surface, with components `(x, y, z)` of type `T`."
struct Normal{T<:AbstractFloat}
    x::T
    y::T
    z::T
end

const VEC_X = Vec(1.0, 0.0, 0.0)
const VEC_Y = Vec(0.0, 1.0, 0.0)
const VEC_Z = Vec(0.0, 0.0, 1.0)

# ─────────────────────────────────────────────────────────────
# Methods to_string and comparison
# ─────────────────────────────────────────────────────────────

"""
Return a string representation of a `Point` in the format:
"[Point] <x:x, y:y, z:z>".
"""
function to_string(p::Point)
    "[Point] <x:$(p.x), y:$(p.y), z:$(p.z)>"
end

"""
Return a string representation of a `Vec` in the format:
"[Vec] <x:x, y:y, z:z>".
"""
function to_string(v::Vec)
    "[Vec] <x:$(v.x), y:$(v.y), z:$(v.z)>"
end

"""
Return a string representation of a `Normal` in the format:
"[Normal] <x:x, y:y, z:z>".
"""
function to_string(n::Normal)
    "[Normal] <x:$(n.x), y:$(n.y), z:$(n.z)>"
end

"Compare two `Point` types. Useful for tests."
function ≈(p::Point, q::Point)
    return isapprox(p.x, q.x, rtol = 1e-5, atol = 1e-5) &&
           isapprox(p.y, q.y, rtol = 1e-5, atol = 1e-5) &&
           isapprox(p.z, q.z, rtol = 1e-5, atol = 1e-5)
end

"Compare two `Vec` types. Useful for tests."
function ≈(v::Vec, u::Vec)
    return isapprox(v.x, u.x, rtol = 1e-5, atol = 1e-5) &&
           isapprox(v.y, u.y, rtol = 1e-5, atol = 1e-5) &&
           isapprox(v.z, u.z, rtol = 1e-5, atol = 1e-5)
end

"Compare two `Normal` types. Useful for tests."
function ≈(n::Normal, m::Normal)
    return isapprox(n.x, m.x, rtol = 1e-5, atol = 1e-5) &&
           isapprox(n.y, m.y, rtol = 1e-5, atol = 1e-5) &&
           isapprox(n.z, m.z, rtol = 1e-5, atol = 1e-5)
end

# ─────────────────────────────────────────────────────────────
# Vector and Point summation
# ─────────────────────────────────────────────────────────────

"Sum between two `Vec` types returns a `Vec`."
function +(v::Vec, u::Vec)
    Vec(v.x + u.x, v.y + u.y, v.z + u.z)
end

"Sum between `Point` and `Vec` returns a `Point`."
function +(p::Point, v::Vec)
    Point(p.x + v.x, p.y + v.y, p.z + v.z)
end

"Difference between two `Vec` types returns a `Vec`."
function -(v::Vec, u::Vec)
    Vec(v.x - u.x, v.y - u.y, v.z - u.z)
end

"Difference between two `Point` types returns a `Vec`."
function -(p::Point, q::Point)
    Vec(p.x - q.x, p.y - q.y, p.z - q.z)
end

"Difference between a `Point` and a `Vec` returns a `Point`."
function -(p::Point, v::Vec)
    Point(p.x - v.x, p.y - v.y, p.z - v.z)
end

# ─────────────────────────────────────────────────────────────
# Scalar Product and Cross Product for Vec and Normal
# ─────────────────────────────────────────────────────────────

"Product of a `Vec` with a scalar."
function *(v::Vec, scalar::Real)
    return Vec(scalar * v.x, scalar * v.y, scalar * v.z)
end

"Product of a scalar with a `Vec`."
function *(scalar::Real, v::Vec)
    return *(v, scalar)
end

"Product of a `Normal` with a scalar."
function *(n::Normal, scalar::Real)
    return Normal(scalar * n.x, scalar * n.y, scalar * n.z)
end

"Product of a scalar with a `Normal`."
function *(scalar::Real, n::Normal)
    return *(n, scalar)
end

"Multiply a `Vec` or a `Normal` with -1."
function neg(v::Union{Vec, Normal})
    (-1) * v
end

"Dot product between two vectors, either of type `Vec` or `Normal`."
function dot(v::Union{Vec, Normal}, u::Union{Vec, Normal})
    return v.x * u.x + v.y * u.y + v.z * u.z
end

"Cross product between two `Vec` types. Returns a `Vec`."
function cross(v::Vec, u::Vec)
    return Vec(v.y * u.z - v.z * u.y, v.z * u.x - v.x * u.z, v.x * u.y - v.y * u.x)
end

"Cross product between a `Vec` and a `Normal`. Returns a `Vec`."
function cross(v::Vec, n::Normal)
    return Vec(v.y * n.z - v.z * n.y, v.z * n.x - v.x * n.z, v.x * n.y - v.y * n.x)
end

"Cross product between a `Normal` and a `Vec`. Returns a `Vec`."
function cross(n::Normal, v::Vec)
    # ( v × u ) = -( u × v )
    return -1 * cross(v, n)
end

"Cross product between two `Normal` types. Returns a `Normal`."
function cross(n::Normal, m::Normal)
    return Normal(n.y * m.z - n.z * m.y, n.z * m.x - n.x * m.z, n.x * m.y - n.y * m.x)
end

# ─────────────────────────────────────────────────────────────
# Normalization for Vec and Normal
# ─────────────────────────────────────────────────────────────

"Given a vector, either of type `Vec` or `Normal`, compute the squared norm, i.e. v.x^2 + v.y^2 + v.z^2."
function squared_norm(v::Union{Vec, Normal})
    return v.x^2 + v.y^2 + v.z^2
end

"Given a vector, either of type `Vec` or `Normal`, compute the norm, i.e. ||v|| = √(v.x^2 + v.y^2 + v.z^2)."
function norm(v::Union{Vec, Normal})
    sqrt(squared_norm(v))
end

"Given a vector, either of type `Vec` or `Normal`, normalize it, i.e. v → v / ||v||."
function normalize(v::Union{Vec, Normal})
    return v / norm(v)
end

# ─────────────────────────────────────────────────────────────
# Conversions between types
# ─────────────────────────────────────────────────────────────

"Convert a `Vec` into a `Normal`."
function vec_to_normal(v::Vec)
    Normal(v.x, v.y, v.z)
end

"Convert a `Point` into a `Vec`."
function point_to_vec(p::Point)
    return Vec(p.x, p.y, p.z)
end

import Base: +, -, *, ≈

"""
    Abstract3DVector

An abstract type representing a 3D vector in space. Concrete subtypes must define 
three coordinate components (`x`, `y`, and `z`) of a numeric type.

# Subtypes
- `Point{T<:Real}`: Represents a point in 3D space.
- `Vec{T<:Real}`: Represents a vector in 3D space.
- `Normal{T<:Real}`: Represents a normal vector in 3D space.
"""
abstract type Abstract3DVector end

"A 3D point with coordinates `(x, y, z)` of type `T`."
struct Point{T<:Real} <: Abstract3DVector
    x::T
    y::T
    z::T
end

"A 3D vector with components `(x, y, z)` of type `T`."
struct Vec{T<:Real} <: Abstract3DVector
    x::T
    y::T
    z::T
end

"A 3D normal vector with components `(x, y, z)` of type `T`. Normal doesn't mean it is a normalized vector: it is the vector orthogonal to a surface."
struct Normal{T<:Real} <: Abstract3DVector
    x::T
    y::T
    z::T
end

"Print components of an `Abstrac3DVector`, e.g. `< x:x, y:y, z:z >`. Return the string."
function to_string(V::Abstract3DVector)
    str = "[$(typeof(V))]< x:" * string(V.x) * ", y:" * string(V.y) * ", z:" * string(V.z) * " >"
end

"Compare two `Abstrac3DVector`, useful for testing."
function ≈(V::Abstract3DVector, U::Abstract3DVector)
    if typeof(V) != typeof(U)
        throw(GeometryError("Cannot compare $(typeof(V)) with $(typeof(U)). Ensure both objects are of the same type."))
    else
        return isapprox(V.x, U.x, rtol = 1e-5, atol = 1e-5) &&
               isapprox(V.y, U.y, rtol = 1e-5, atol = 1e-5) &&
               isapprox(V.z, U.z, rtol = 1e-5, atol = 1e-5)
    end
end

# Summation and subtraction

"Adding vector `v` to vector `u` creates a new vector."
function +(v::Vec, u::Vec)
    Vec(v.x + u.x, v.y + u.y, v.z + u.z)
end

"Adding vector `v` to point `p` creates a new point."
function +(p::Point, v::Vec)
    Point(p.x + v.x, p.y + v.y, p.z + v.z)
end

"Adding point `p` to vector `v` creates a new point."
function +(v::Vec, p::Point)
    +(p, v)
end

"Subtracting two vectors gives a vector."
function -(v::Vec, u::Vec)
    Vec(v.x - u.x, v.y - u.y, v.z - u.z)
end

"Subtracting two points gives a vector."
function -(p::Point, q::Point)
    Vec(p.x - q.x, p.y - q.y, p.z - q.z)
end

"Substracting a vector `v` to point `p` creates a new point."
function -(p::Point, v::Vec)
    Point(p.x - v.x, p.y - v.y, p.z - v.z)
end

"Substracting a point `p` to vector `v` creates a new point."
function -(v::Vec, p::Point)
    Point(v.x - p.x, v.y - p.y, v.z - p.z)
end

# Product by a scalar
"Product of a `Vec` or `Normal` with a scalar."
function *(v::Abstract3DVector, scalar::Real)
    if v isa Point
        throw(
            GeometryError(
                "Cannot multiply a scalar with a Point type. Please use a Vec or Normal type.",
            ),
        )
    else
        return typeof(v)(scalar * v.x, scalar * v.y, scalar * v.z)
    end
end
"Product of a `Vec` or `Normal` with a scalar."
function *(scalar::Real, v::Abstract3DVector)
    *(v, scalar)
end

"Multiply `Vec` or `Normal` with -1."
function neg(v::Abstract3DVector)
    if v isa Point
        throw(
            GeometryError(
                "Cannot multiply a scalar with a Point type. Please use a Vec or Normal type.",
            ),
        )
    else
        (-1) * v
    end
end

# Dot product
""
function dot(v::Abstract3DVector, u::Abstract3DVector)
    if v isa Point || u isa Point
        throw(
            GeometryError(
                "Cannot compute dot product with a Point type. Please use a Vec or Normal type.",
            ),
        )
    else
        return v.x * u.x + v.y * u.y + v.z * u.z
    end
end

# Cross product
# Cross product of a vector with the vetor itself is the null vector
""
function cross(v::Abstract3DVector, u::Abstract3DVector)
    if v isa Point || u isa Point
        throw(
            GeometryError(
                "Cannot compute dot product with Point type. Please use a Vec or Normal type.",
            ),
        )
    elseif v ≈ u
        return Vec(0.0,0.0,0.0)
    elseif v isa Normal && u isa Normal
        return Normal(
            v.y * u.z - v.z * u.y,
            v.z * u.x - v.x * u.z,
            v.x * u.y - v.y * u.x,
        )
    else
        return Vec(
            v.y * u.z - v.z * u.y,
            v.z * u.x - v.x * u.z,
            v.x * u.y - v.y * u.x,
        )
    end
end

# Norm of a vector, squared norm and normalization
""
function squared_norm(v::Abstract3DVector)
    if v isa Point
        throw(
            GeometryError(
                "Cannot compute the norm of a Point type. Please use a Vec or Normal type.",
            ),
        )
    else
        return v.x^2 + v.y^2 + v.z^2
    end
end

""
function norm(v::Abstract3DVector)
    sqrt(squared_norm(v))
end

""
function normalize(v::Abstract3DVector)
    if v isa Point
        throw(
            GeometryError(
                "Cannot normalize a Point type. Please use a Vec or Normal type.",
            ),
        )
    else
        return v / norm(v) # controllare che julia capisca come è definito il /; noi abbiamo definito *
    end
end


# Conversions
"Convert a `Vec` into `Normal`, i.e. normalizing a vector??."
Normal(v::Vec) = Normal(v.x, v.y, v.z)
"Convert a `Point` into `Vec`."
Vec(p::Point) = Vec(p.x, p.y, p.z)
