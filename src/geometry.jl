# Vectors
struct Vec
    x::Real
    y::Real
    z::Real
end
# Point
struct Point
    x::Real
    y::Real
    z::Real
end
# Normal
struct Normal
    x::Real
    y::Real
    z::Real
end

function to_string(V)
    str = "< x:" * string(V.r) * ", y:" * string(V.y) * ", z:" * string(V.z) * " >"
    return str
end

