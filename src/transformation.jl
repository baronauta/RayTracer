import LinearAlgebra: I

struct Transformation{T<:Real}
    M::Matrix{T}
    invM::Matrix{T}
end

const IDENTITY_MATR4x4 = Matrix{Float32}(I, 4, 4)

function _is_consistent(T::Transformation)
    prod = T.M * T.invM
    prod ≈ IDENTITY_MATR4x4
end

function translation(v::Vec)
    M = []
end
