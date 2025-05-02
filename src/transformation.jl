import Base: *

# ─────────────────────────────────────────────────────────────
# Defining new types:
#   - HomMatrix
#   - Transformation
# ─────────────────────────────────────────────────────────────

struct HomMatrix{T<:AbstractFloat}
    matrix::Matrix{T}
end

struct Transformation{T<:AbstractFloat}
    M::HomMatrix{T}
    invM::HomMatrix{T}
end

const IDENTITY_MATR4x4 = [1. 0. 0. 0.; 0. 1. 0. 0.; 0. 0. 1. 0.; 0. 0. 0. 1.]

"Product between two `HomMatrix` types. Returns a `HomMatrix` type."
function *(A::HomMatrix, B::HomMatrix)
    return HomMatrix(A.matrix * B.matrix)
end

"Check the product between the transformation matrix and its inverse, i.e M * M^(-1) = Id."
function _is_consistent(T::Transformation)
    prod = (T.M * T.invM).matrix
    prod ≈ IDENTITY_MATR4x4
end

"""
Given a `Transformation`, return the inverse transformation. 
With reference to the `Transformation` type, these means swapping fields `M` and `invM`.
"""
function inverse(T::Transformation)
    return Transformation(T.invM, T.M)
end

"Compare two `HomMatrix` types. Useful for tests."
function ≈(M::HomMatrix, N::HomMatrix)
    M.matrix ≈ N.matrix
end

"Compare two `Transformation` types. Useful for tests."
function ≈(T::Transformation, S::Transformation)
    T.M ≈ S.M && T.invM ≈ S.invM
end

# ─────────────────────────────────────────────────────────────
# - Transformation * Transformation
# - Transformation * Point/Vec/Normal
# ─────────────────────────────────────────────────────────────

"""
Compute the product of two `Transformation` types. Given transformations `A` and `B`,
their product is `A ⋅ B`. The inverse of the product is `(A ⋅ B)^(-1) = B^(-1) ⋅ A^(-1)`.
"""
function *(A::Transformation, B::Transformation)
    M = A.M * B.M
    invM = B.invM * A.invM
    return Transformation(M, invM)
end

"Transformation of a `Point`. It is transformed into a `Point`."
function *(T::Transformation, p::Point)
    # In homogeneous coordinates a point is (p.x, p.y, p.z, 1)
    p4 = [p.x, p.y, p.z, 1]
    Tp4 = T.M.matrix * p4
    # Return the point in 3D coordinates
    return Point(Tp4[1], Tp4[2], Tp4[3])
end

"Transformation of a `Vec`. It is transformed into a `Vec`."
function *(T::Transformation, v::Vec)
    # In homogeneous coordinates a vector is (v.x, v.y, v.z, 0)
    v4 = [v.x, v.y, v.z, 0]
    Tv4 = T.M.matrix * v4
    # Return the vector in 3D coordinates
    return Vec(Tv4[1], Tv4[2], Tv4[3])
end

"""
Transformation of a `Normal`. It is transformed into a `Normal`. 
Let the direct transformation be `M`, then a normal vector is transformed with `(M^(-1))^T`.
"""
function *(T::Transformation, n::Normal)
    # In homogeneous coordinates a vector is (v.x, v.y, v.z, 0)
    # A normal vector is a vector with norm 1
    n4 = [n.x, n.y, n.z, 0]
    Tn4 = transpose(T.invM.matrix) * n4
    # Return the vector in 3D coordinates
    return Normal(Tn4[1], Tn4[2], Tn4[3])
end

# ─────────────────────────────────────────────────────────────
# Translation, Rotation and Scaling
# ─────────────────────────────────────────────────────────────

"""
Create a translation transformation by a vector `v` of type `Vec`.
The transformation matrix moves points by the vector `v`, and the inverse
matrix moves points in the opposite direction.

# Arguments
- `v::Vec`: A vector specifying the translation along the x, y, and z axes.

# Returns
A `Transformation` type that applies the translation and its inverse.
"""
function translation(v::Vec)
    M = HomMatrix([
        1 0 0 v.x
        0 1 0 v.y
        0 0 1 v.z
        0 0 0 1
    ])
    invM = HomMatrix([
        1 0 0 -v.x
        0 1 0 -v.y
        0 0 1 -v.z
        0 0 0 1
    ])
    return Transformation(M, invM)
end

"""
Create a rotation transformation around the x-axis by an angle `ang_deg` (in degrees).
The transformation matrix rotates points counterclockwise around the x-axis, and the inverse
matrix applies the reverse rotation.

# Arguments
- `ang_deg::Real`: The rotation angle in degrees.

# Returns
A `Transformation` instance representing the rotation around the x-axis and its inverse.
"""
function rotation_x(ang_deg::Real)
    # Convert degrees to radians
    ang_rad = deg2rad(ang_deg)

    cosang = cos(ang_rad)
    sinang = sin(ang_rad)

    M = HomMatrix([
        1 0 0 0
        0 cosang -sinang 0
        0 sinang cosang 0
        0 0 0 1
    ])
    invM = HomMatrix([
        1 0 0 0
        0 cosang sinang 0
        0 -sinang cosang 0
        0 0 0 1
    ])
    return Transformation(M, invM)
end

"""
Create a rotation transformation around the y-axis by an angle `ang_deg` (in degrees).
The transformation matrix rotates points counterclockwise around the y-axis, and the inverse
matrix applies the reverse rotation.

# Arguments
- `ang_deg::Real`: The rotation angle in degrees.

# Returns
A `Transformation` instance representing the rotation around the y-axis and its inverse.
"""
function rotation_y(ang_deg::Real)
    # Convert degrees to radians
    ang_rad = deg2rad(ang_deg)

    cosang = cos(ang_rad)
    sinang = sin(ang_rad)

    M = HomMatrix([
        cosang 0 sinang 0
        0 1 0 0
        -sinang 0 cosang 0
        0 0 0 1
    ])
    invM = HomMatrix([
        cosang 0 -sinang 0
        0 1 0 0
        sinang 0 cosang 0
        0 0 0 1
    ])
    return Transformation(M, invM)
end

"""
Create a rotation transformation around the z-axis by an angle `ang_deg` (in degrees).
The transformation matrix rotates points counterclockwise around the z-axis, and the inverse
matrix applies the reverse rotation.

# Arguments
- `ang_deg::Real`: The rotation angle in degrees.

# Returns
A `Transformation` instance representing the rotation around the z-axis and its inverse.
"""
function rotation_z(ang_deg::Real)
    # Convert degrees to radians
    ang_rad = deg2rad(ang_deg)

    cosang = cos(ang_rad)
    sinang = sin(ang_rad)

    M = HomMatrix([
        cosang -sinang 0 0
        sinang cosang 0 0
        0 0 1 0
        0 0 0 1
    ])
    invM = HomMatrix([
        cosang sinang 0 0
        -sinang cosang 0 0
        0 0 1 0
        0 0 0 1
    ])
    return Transformation(M, invM)
end

"""
Create a scaling transformation by the factors `sx`, `sy`, and `sz` along the x, y, and z axes, respectively.
The transformation matrix scales points, and the inverse matrix applies the reverse scaling.

# Arguments
- `sx::Real`: Scaling factor along the x-axis.
- `sy::Real`: Scaling factor along the y-axis.
- `sz::Real`: Scaling factor along the z-axis.

# Throws
- `GeometryError`: If any scaling factor is zero.

# Returns
A `Transformation` instance representing the scaling transformation and its inverse.
"""
function scaling(sx::Real, sy::Real, sz::Real)
    if sx == 0 || sy == 0 || sz == 0
        throw(GeometryError("Cannot scale with zero factor."))
    else
        M = HomMatrix([
            sx 0 0 0
            0 sy 0 0
            0 0 sz 0
            0 0 0 1
        ])
        invM = HomMatrix([
            1/sx 0 0 0
            0 1/sy 0 0
            0 0 1/sz 0
            0 0 0 1
        ])
    end
    return Transformation(M, invM)
end
