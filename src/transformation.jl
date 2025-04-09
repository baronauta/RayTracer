import Base: *
import LinearAlgebra: I

struct HomMatrix{T<:AbstractFloat}
    M::Matrix{T}
end

struct Transformation{T<:AbstractFloat}
    M::HomMatrix{T}
    invM::HomMatrix{T}
end

const IDENTITY_MATR4x4 = Matrix{Float32}(I, 4, 4)

"Check that the product between the transformation matrix and its inverse is the identity matrix."
function _is_consistent(T::Transformation)
    prod = T.M * T.invM
    prod ≈ IDENTITY_MATR4x4
end

"Let `T` be a `Transformation` with field `T.M = A` and `T.invM = A^(-1)`. Return a `Transformation`, say `S`
with inverted fiels, i.e. `S.M = A^(-1)` and `S.invM = A`."
function inverse(T::Transformation)
    return Transformation(T.invM, T.M)
end

# Product

"Product between two `Transformation`. Let `A` and `B` the direct transformation, their product is `A ⋅ B`.
The inverse `(A ⋅ B)^(-1)` is `B^(-1) ⋅ A^(-1)`."
function *(A::Transformation, B::Transformation)
    M = HomMatrix(A.M * B.M)
    invM = HomMatrix(B.invM * A.invM)
    return Transformation(M, invM)
end

"Transformation of a `Point`. It is transformed into a `Point`."
function *(T::Transformation, p::Point)
    # In homogeneous coordinates a point is (p.x, p.y, p.z, 1)
    p4 = [p.x, p.y, p.z, 1]
    Tp4 = T.M * p4
    # Return the point in 3D coordinates
    return Point(Tp4[1], Tp4[2], Tp4[3])
end

"Transformation of a `Vec`. It is transformed into a `Vec`."
function *(T::Transformation, v::Vec)
    # In homogeneous coordinates a vector is (v.x, v.y, v.z, 0)
    v4 = [v.x, v.y, v.z, 0]
    Tv4 = T.M * v4
    # Return the vector in 3D coordinates
    return Vec(Tv4[1], Tv4[2], Tv4[3])
end

"Transformation of a `Normal`. It is transformed into a `Normal`. Let the direct transformation to be `M`,
then a normal vector is transformed by `(M^(-1))^T`."
function *(T::Transformation, n::Normal)
    # In homogeneous coordinates a vector is (v.x, v.y, v.z, 0)
    # A normal vector is a vector with norm 1
    n4 = [n.x, n.y, n.z, 0]
    Tn4 = transpose(T.invM) * n4
    # Return the vector in 3D coordinates
    return Normal(Tn4[1], Tn4[2], Tn4[3])
end

# Constructors of transformation: translation, rotation, scaling

""
function translation(v::Vec)
    M = HomMatrix([
        1  0  0  v.x;
        0  1  0  v.y;
        0  0  1  v.z;
        0  0  0  1
    ])
    invM = HomMatrix([
        1  0  0  -v.x;
        0  1  0  -v.y;
        0  0  1  -v.z;
        0  0  0   1
    ])
    return Transformation(M, invM)
end

function rotation(theta::Real)
    ##
    ##
    return Transformation(M, invM)
end

function scale(factor::Real)
    ##
    ##
    return Transformation(M, invM)
end
