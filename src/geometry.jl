# Point
struct Point
    x::Real
    y::Real
    z::Real
end

# Vector:
struct Vec
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

# Conversion to string
function to_string(V)
    str = "< x:" * string(V.r) * ", y:" * string(V.y) * ", z:" * string(V.z) * " >"
    return str
end

# Obj1 ≈ Obj2
function Base.:≈(o1, o2)
    if typeof(o1) != typeof(o2)
        #not sure object is a great name in Julia, must verify
        throw(GeometryError("Cannot compare $(typeof(o1)) with $(typeof(o2)). Ensure both objects are of the same type."))
    else
        return (isapprox(o1.x, o2.x, rtol = 1e-5, atol = 1e-5) && 
                isapprox(o1.y, o2.y, rtol = 1e-5, atol = 1e-5) && 
                isapprox(o1.z, o2.z, rtol = 1e-5, atol = 1e-5))
    end
end


# Vector & Normal

# scalar product
# ATTENZIONE NON C'è TRA PUNTO E SCALARE??
function Base.:*(scalar::Real, o2)
    if o2 isa Point
        throw(GeometryError("Cannot multiply a scalar with a Point type. Please use a Vec or Normal type.")) 
    else
        return typeof(o2)(scalar*o2.x,scalar*o2.y,scalar*o2.z)
    end
end
Base.:*(o1, scalar::Real) = scalar * o1

# negation 
# not used Base.:-(v) = -1 * v perchè se poi devo fare sottrazioni tra vettori magari da fastidio con l'overloading di a-b
function neg(o1)
    if o1 isa Point
        throw(GeometryError("Cannot make a negative Point. Please use a Vec or Normal type.")) 
    else
        return (-1)*o1
    end
end


# dot product ATTENZIONE LINEAR ALGEBRA
# ATTENZIONE NORMAL NORMAL NO?
function dot(o1, o2)
    if o1 isa Point || o2 isa Point
        throw(GeometryError("Cannot compute dot product with a Point type. Please use a Vec or Normal type."))
    elseif o1 isa Normal && o2 isa Normal
        throw(GeometryError("Cannot compute dot product between two Normal types. Please compute dot product between Vec and Vec or Vec and Normal.")) 
    else
        return o1.x * o2.x + o1.y * o2.y + o1.z * o2.z
    end
end

# cross product ATTENZIONE LINEAR ALGEBRA
# ATTENZIONE risultato cross tra vec e norm che cos'è? per ora solo vettore
function cross(o1, o2)
    if o1 isa Point || o2 isa Point
        throw(GeometryError("Cannot make dot product with Point type. Please use a Vec or Normal type.")) 
    else
        return Vec(o1.y * o2.z - o1.z * o2.y,
                   o1.z * o2.x - o1.x * o2.z,
                   o1.x * o2.y - o1.y * o2.x)
    end
end

# norm and squared norm
function squared_norm(o)
    if o isa Point
        throw(GeometryError("Cannot make the norm of a Point type. Please use a Vec or Normal type.")) 
    else
        return o.x^2 + o.y^2 + o.z^2
    end
end
norm(o) = √(squared_norm(o))

# normalize
function normalize(o)
    if o isa Point
        throw(GeometryError("Cannot normalize a Point type. Please use a Vec or Normal type.")) 
    else
        return norm(o)^(-1) * o
    end
end

# Conversions
Normal(v::Vec) = Normal(v.x, v.y, v.z)
Vec(p::Point) = Vec(p.x, p.y, p.z)


# Sum

# function Base.:+(o1, o2)
#     return
# end
# function Base.:-(o1,o2)
#     return
# end

#=
    STATUS INDEX
    Vec:
- [x] Conversion to string, e.g., Vec(x=0.4, y=1.3, z=0.7);
- [x] Comparison between vectors (for tests), using functions like are_close;
- [] Sum and difference between vectors;
- [x] Product by a scalar and negation (Vec.neg() returns −v−v);
- [x] Dot product between two vectors and cross product;
- [x] Calculation of ∥v∥2∥v∥2 (squared_norm) and of ∥v∥∥v∥ (norm);
- [x] Function that normalizes the vector: v→v/∥v∥v→v/∥v∥;
- [x] Function that converts a Vec into a Normal.

    Normal:
- [x] Conversion to string, e.g., Normal(x=0.4, y=1.3, z=0.7);
- [x] Comparison between normals (for tests);
- [x] Negation of a normal (−n⃗−n);
- [x] Multiplication by a scalar;
- [x] Dot product Vec·Normal and cross product Vec×Normal and Normal×Normal;
- [x] Calculation of ∥n∥2∥n∥2 (squared_norm) and of ∥n∥∥n∥ (norm);
- [x] Function that normalizes the normal: n→n/∥n∥n→n/∥n∥.

    Point:
- [x] Conversion to string, e.g., Point(x=0.4, y=1.3, z=0.7);
- [x] Comparison between points (for tests);
- [] Sum between Point and Vec, returning a Point;
- [] Difference between two Points, returning a Vec;
- [] Difference between Point and Vec, returning a Point;
- [x] Conversion from Point to Vec (Point.to_vec()).
=#