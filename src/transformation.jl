import LinearAlgebra: I

struct HomMatrix{T<:AbstractFloat}
    M::Matrix{T}
end

struct Transformation{T<:AbstractFloat}
    M::HomMatrix{T}
    invM::HomMatrix{T}
end

const IDENTITY_MATR4x4 = Matrix{Float32}(I, 4, 4)

function _is_consistent(T::Transformation)
    prod = T.M * T.invM
    prod ≈ IDENTITY_MATR4x4
end

function translation(v::Vec)
    M = []
end
