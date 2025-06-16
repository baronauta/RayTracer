# ─────────────────────────────────────────────────────────────
# Implement Constructive Solid Geometry (CSG)
# ─────────────────────────────────────────────────────────────

"""
Enumerated type representing the possible CSG operations:
- `UNION`: the resulting shape includes the volume of both shapes;
- `DIFFERENCE`: the resulting shape includes only the volume of the first shape minus the second;
- `INTERSECTION`: the resulting shape includes only the shared volume between the two shapes.
"""
@enum Operation begin
    UNION
    DIFFERENCE
    INTERSECTION
    FUSION
end

"""
A Constructive Solid Geometry (CSG) shape defined by applying an operation
(`UNION`, `DIFFERENCE`, or `INTERSECTION`) between two shapes.

Fields:
- `obj1::Shape`: the first shape involved in the operation;
- `obj2::Shape`: the second shape involved in the operation;
- `operation::Operation`: the CSG operation to apply.

Notes:
- **Shape order matters**: `obj1 - obj2` is not the same as `obj2 - obj1`.
- **Shapes can be nested CSGs**: both `obj1` and `obj2` may themselves be `CSG` objects.
"""
struct CSG{T<:AbstractFloat} <: Shape{T}
    obj1::Shape
    obj2::Shape
    operation::Operation
end

"""
Compares two shapes for equality.
Returns `true` if the shapes have the same type and same transformations.

Note: Materials are not compared.
"""
function ≈(obj1::Shape, obj2::Shape)
    return ((typeof(obj1) == typeof(obj2)) && (obj1.transformation ≈ obj2.transformation))
end

"""
Compares two CSG shapes for equality.
Returns `true` if the CSGs have the same obj and operations.
"""
function ≈(csg1::CSG, csg2::CSG)
    if (csg1.operation == csg2.operation)
        if csg1.operation == UNION || csg1.operation == INTERSECTION
            a = ((csg1.obj1 == csg2.obj1) && (csg1.obj2 == csg2.obj2))
            b = ((csg1.obj2 == csg2.obj1) && (csg2.obj2 == csg1.obj1))
            return a || b
        elseif csg1.operation == DIFFERENCE
            return ((csg1.obj1 == csg2.obj1) && (csg1.obj2 == csg2.obj2))
        else
            throw(CsgError("undefined operation $(csg1.operation)"))
        end
    else
        return false
    end
end

"""
Checks whether a CSG construction is valid.

Not accepted `csg` with 2 identical overlapped objects.
"""
function valid_csg(csg::CSG)
    (csg.obj1 == csg.obj2) &&
        throw(CsgError("cannot make csg with two overlapped same objects"))
    return true
end

"""
CSG outer costructor.
validates the csg before returning it.
"""
function CSG(obj1::Shape{T}, obj2::Shape{T}, operation::Operation) where {T<:AbstractFloat}
    csg = CSG{T}(obj1, obj2, operation)
    valid_csg(csg)
    return csg
end

"""
---
Check whether a `HitRecord hit` is inside a `CSG` object.
"""
function is_inside(hit::HitRecord, csg::CSG)
    if csg.operation == UNION || csg.operation == FUSION
        # hit records can be inside one obj or the other
        return (is_inside(hit, csg.obj1) || (is_inside(hit, csg.obj2)))

    elseif csg.operation == INTERSECTION
        # hit records must be in obj AND in obj 2
        return (is_inside(hit, csg.obj1) && (is_inside(hit, csg.obj2)))

    elseif csg.operation == DIFFERENCE
        # hit records can be on obj1 if not in ob2 and in ob2 if not in on1
        return (is_inside(hit, csg.obj1) && !is_inside(hit, csg.obj2))
    end
end

"""
    valid_hit(hr::HitRecord, obj::Shape, csg::CSG) -> Bool

Determines whether a given `HitRecord` is valid based on the CSG operation between two shapes.

Arguments:
- `hr`: the hit record to evaluate.
- `obj`: the *other* shape involved in the CSG operation (not the one that generated `hr`).
- `csg`: the `CSG` object describing the two shapes and the boolean operation.

Returns `true` if the hit should be included according to the CSG operation (`UNION`, `INTERSECTION`, `FUSION`, or `DIFFERENCE`), `false` otherwise.
"""
function valid_hit(hr::HitRecord, obj::Shape, csg::CSG)
    is_obj1 = (csg.obj1 ≈ hr.shape)
    op = csg.operation

    if op == UNION
        return true
    elseif op == INTERSECTION
        return is_inside(hr, obj)
    elseif op == FUSION
        return !is_inside(hr, obj)
    elseif op == DIFFERENCE
        return (is_obj1 && !is_inside(hr, obj)) || (!is_obj1 && is_inside(hr, obj))
    else
        throw(CsgError("undefined operation $(op)"))
    end
end

"""
    check_sort_records(a::Vector{HitRecord{T}}, b::Vector{HitRecord{T}}, csg::CSG{T}) -> Vector{HitRecord{T}}

Merges two sorted lists of hit records (`a` and `b`) from two shapes involved in a CSG operation.

Each hit is validated using `valid_hit`, based on whether it should be included in the final result according to the operation in `csg`.

Returns a sorted vector of valid `HitRecord`s resulting from the CSG operation.
"""
function check_sort_records(a::Vector{HitRecord{T}}, b::Vector{HitRecord{T}}, csg::CSG{T}) where T
    result = Vector{HitRecord{T}}()
    i = 1
    j = 1
    println("\n")
    while i <= length(a) && j <= length(b)
        if a[i].t <= b[j].t
            if valid_hit(a[i], csg.obj2, csg)
                println("- $(a[i].world_point) is inside $(typeof(csg.obj2)):  ", is_inside(a[i], csg.obj2))
                push!(result, a[i])
                println("PUSHED: a[$i] = $(a[i].world_point)")

            end
            i += 1
        else
            if valid_hit(b[j], csg.obj1, csg)
                println("- $(b[j].world_point) is inside $(typeof(csg.obj1)):  ", is_inside(b[j], csg.obj1))
                push!(result, b[j])
                println("PUSHED: b[$j] = $(b[j].world_point)")
            end
            j += 1
        end
    end

    # check remaining elements
    while i <= length(a)
        if valid_hit(a[i], csg.obj2, csg)
            println("- $(a[i].world_point) is inside $(typeof(csg.obj2)):  ", is_inside(a[i], csg.obj2))
            push!(result, a[i])
            println("PUSHED: a[$i] = $(a[i].world_point)")
        end
        i += 1
    end
    while j <= length(b)
        if valid_hit(b[j], csg.obj1, csg)
            println("- $(b[j].world_point) is inside $(typeof(csg.obj1)):  ", is_inside(b[j], csg.obj1))
            push!(result, b[j])
            println("PUSHED: b[$j] = $(b[j].world_point)")
        end
        j += 1
    end

    return result
end

"""
Checks if a `Ray` intersects the `CSG`.
Return a sorted list of all `HitRecord`s or a list of `nothing` if no intersection is found.
"""
function ray_intersection(csg::CSG, ray::Ray; all=false)

    hit_array_1 = ray_intersection(csg.obj1, ray; all = true)
    println("\n::::::::::\n",hit_array_1)
    hit_array_2 = ray_intersection(csg.obj2, ray; all = true)
    println("\n::::::::::\n",hit_array_2)
    real_hits_1 = filter(!isnothing, hit_array_1)
    real_hits_2 = filter(!isnothing, hit_array_2)

    if (!isempty(real_hits_1) && !isempty(real_hits_2))
        hit_list = check_sort_records(real_hits_1, real_hits_2, csg)
        println("chosen:")
        for hit in hit_list
            println(hit.world_point)
        end
    else
        return [nothing]
    end
    
    (all == true) ? (return hit_list) : return hit_list[1]
    
end