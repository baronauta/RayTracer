mutable struct PCG
    state::UInt64
    inc::UInt64
end

"""
    PCG(; init_state=42, init_seq=54)

Create and initialize a PCG (Permuted Congruential Generator) random number generator.
`init_state` and `init_seq` are optional seeds.
"""
function PCG(;init_state=42, init_seq=54)
    # Throw a random number and discard it
    state = 0
    inc = (init_seq << 1) | 1
    pcg = PCG(state, inc)
    random!(pcg)
    # Throw a random number and discard it
    pcg.state = pcg.state + init_state
    random!(pcg)
    # The PCG is ready to be used
    return pcg
end

"""
    random!(pcg::PCG) -> UInt32

Generate a new 32-bit random number using the PCG algorithm,
updating the internal state.
"""
function random!(pcg::PCG)::UInt32
    oldstate = pcg.state
    # Update the state of the PCG
    pcg.state = oldstate * 6364136223846793005 + pcg.inc
    # Return UInt32 computed as follows, i.e. a number in range [0, 2³² - 1].
    # ⊻ is the xor operator in julia
    xorshifted = UInt32((((oldstate >> 18) ⊻ oldstate) >> 27) & typemax(UInt32))
    rot = UInt32(oldstate >> 59)
    return UInt32((xorshifted >> rot) | (xorshifted << ((-rot) & 31)))
end

"""
    random_float!(pcg::PCG) -> Float64

Generate a random floating-point number in [0, 1] using PCG.
"""
function random_float!(pcg::PCG)::Float64
    return Float64(random!(pcg)) / (UInt32(typemax(UInt32)) + 1)
end