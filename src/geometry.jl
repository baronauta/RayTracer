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

"A 3D normal vector with components `(x, y, z)` of type `T`."
# Ha senso definire un vettore come Normal anche se non è normal?
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
# When I multiply a Normal by a scalar, it is not a Normal anymore, and it becomes a Vec

"Product of a `Vec` or `Normal` with a scalar."
function *(v::Abstract3DVector, scalar::Real)
    if v isa Point
        throw(
            GeometryError(
                "Cannot multiply a scalar with a Point type. Please use a Vec or Normal type.",
            ),
        )
    else
        return Vec(scalar * v.x, scalar * v.y, scalar * v.z)
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
# Cross product between two Normal is a Normal
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
        return v / norm(v)
    end
end


# Conversions
"Convert a `Vec` into `Normal`, i.e. normalizing a vector??."
Normal(v::Vec) = Normal(normalize(v))
"Convert a `Point` into `Vec`."
Vec(p::Point) = Vec(p.x, p.y, p.z)
