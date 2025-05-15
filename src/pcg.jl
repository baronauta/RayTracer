mutable struct PCG
    state::UInt64
    inc::UInt64
end

function random!(pcg::PCG)
    oldstate = pcg.state
    # Update the state of the PCG
    pcg.state = oldstate * 6364136223846793005 + pcg.inc
    # Return UInt32 computed as follows, i.e. a number in range [0, 2³² - 1].
    # ⊻ is the xor operator in julia
    xorshifted = UInt32((((oldstate >> 18) ⊻ oldstate) >> 27) & typemax(UInt32))
    rot = UInt32(oldstate >> 59)
    return UInt32((xorshifted >> rot) | (xorshifted << ((-rot) & 31)))
end

"Initialize the PCG."
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


