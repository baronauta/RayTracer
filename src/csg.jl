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
- `operation::Operation`: the CSG operation to apply;
- `transformation::Transformation`: the general transformation of objects ensemble.

Notes:
- **Shape order matters**: `obj1 - obj2` is not the same as `obj2 - obj1`.
- **Shapes can be nested CSGs**: both `obj1` and `obj2` may themselves be `Csg` objects.
"""
struct Csg{T<:AbstractFloat} <: Shape{T}
    obj1::Shape
    obj2::Shape
    operation::Operation
    transformation::Transformation
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
Compares two Csg shapes for equality.
Returns `true` if the CSGs have the same obj and operations.
"""
function ≈(csg1::Csg, csg2::Csg)
    if (csg1.operation == csg2.operation)
        if csg1.transformation ≈ csg2.transformation
            if csg1.operation == UNION || csg1.operation == INTERSECTION || csg1.operation == FUSION
                a = ((csg1.obj1 ≈ csg2.obj1) && (csg1.obj2 ≈ csg2.obj2))
                b = ((csg1.obj2 ≈ csg2.obj1) && (csg2.obj2 ≈ csg1.obj1))
                return a || b
            elseif csg1.operation == DIFFERENCE
                return ((csg1.obj1 ≈ csg2.obj1) && (csg1.obj2 ≈ csg2.obj2))
            else
                throw(CsgError("undefined operation $(csg1.operation)"))
            end
        else
            return false
        end
    else
        return false
    end
end

"""
Checks whether a Csg construction is valid.

Not accepted `csg` with 2 identical overlapped objects.
"""
function valid_csg(csg::Csg)
    (csg.obj1 ≈ csg.obj2) &&
        throw(CsgError("cannot make csg with two overlapped same objects"))
    return true
end

"""
Csg outer default costructor, transformation is set to Identity.
validates the csg before returning it.
"""
function Csg(obj1::Shape{T}, obj2::Shape{T}, operation::Operation) where {T<:AbstractFloat}
    transformation =
        Transformation(HomMatrix(IDENTITY_MATR4x4), HomMatrix(IDENTITY_MATR4x4))
    csg = Csg{T}(obj1, obj2, operation, transformation)
    valid_csg(csg)
    return csg
end

"""
Csg outer costructor, with specified transformation.
validates the csg before returning it.
"""
function Csg(obj1::Shape{T}, obj2::Shape{T}, operation::Operation, transformation::Transformation) where {T<:AbstractFloat}
    csg = Csg{T}(obj1, obj2, operation, transformation)
    valid_csg(csg)
    return csg
end

"""
---
Check whether a `HitRecord hit` is inside a `Csg` object.

Note: this can be a nested csg, it consider the overall parent CSG transformation as an external parameter to be passed.
"""
function is_inside(hit::HitRecord, csg::Csg, t::Transformation)
    transformation = t * csg.transformation
    if csg.operation == UNION || csg.operation == FUSION
        # hit records can be inside one obj or the other
        return (is_inside(hit, csg.obj1, transformation) || (is_inside(hit, csg.obj2, transformation)))

    elseif csg.operation == INTERSECTION
        # hit records must be in obj AND in obj 2
        return (is_inside(hit, csg.obj1, transformation) && (is_inside(hit, csg.obj2, transformation)))

    elseif csg.operation == DIFFERENCE
        # hit records can be on obj1 if not in ob2 and in ob2 if not in on1
        return (is_inside(hit, csg.obj1, transformation) && !is_inside(hit, csg.obj2, transformation))
    end
end

"if a hit belongs to an obj"
function _belongs(hr::HitRecord, obj::Shape)
    if obj isa Csg
        return ((hr.shape ≈ obj.obj1) || (hr.shape ≈ obj.obj2))
    else
        return (hr.shape ≈ obj)
    end
end

"""
    valid_hit(hr::HitRecord, obj::Shape, csg::Csg) -> Bool

Determines whether a given `HitRecord` is valid based on the Csg operation between two shapes.

Arguments:
- `hr`: the hit record to evaluate.
- `obj`: the *other* shape involved in the Csg operation (not the one that generated `hr`).
- `csg`: the `Csg` object describing the two shapes and the boolean operation.

Returns `true` if the hit should be included according to the Csg operation (`UNION`, `INTERSECTION`, `FUSION`, or `DIFFERENCE`), `false` otherwise.
"""
function valid_hit(hr::HitRecord, obj::Shape, csg::Csg)
    is_obj1 = _belongs(hr, csg.obj1)
    op = csg.operation

    if op == UNION
        return true
    elseif op == INTERSECTION
        return is_inside(hr, obj, csg.transformation)
    elseif op == FUSION
        return !is_inside(hr, obj, csg.transformation)
    elseif op == DIFFERENCE
        return (is_obj1 && !is_inside(hr, obj, csg.transformation)) || (!is_obj1 && is_inside(hr, obj, csg.transformation))
    else
        throw(CsgError("undefined operation $(op)"))
    end
end

"""
    check_sort_records(a::Vector{HitRecord{T}}, b::Vector{HitRecord{T}}, csg::Csg{T}) -> Vector{HitRecord{T}}

Merges two sorted lists of hit records (`a` and `b`) from two shapes involved in a Csg operation.

Each hit is validated using `valid_hit`, based on whether it should be included in the final result according to the operation in `csg`.

Returns a sorted vector of valid `HitRecord`s resulting from the Csg operation.
"""
function check_sort_records(a::Vector{HitRecord{T}}, b::Vector{HitRecord{T}}, csg::Csg{T}) where T
    result = Vector{HitRecord{T}}()
    i = 1
    j = 1
    # debug: println("\n")
    while i <= length(a) && j <= length(b)
        if a[i].t <= b[j].t
            # debug: println("-- $(a[i].world_point) belongs to obj1:  $(a[i].shape ≈ csg.obj1)\tshape: $(typeof(a[i].shape)) ; obj1: $(typeof(csg.obj1))")
            if valid_hit(a[i], csg.obj2, csg)
                # debug: println("- $(a[i].world_point) is inside $(typeof(csg.obj2)):  ", is_inside(a[i], csg.obj2))
                push!(result, a[i])
                # debug: println("PUSHED: a[$i] = $(a[i].world_point)")

            end
            i += 1
        else
            # debug: println("-- $(b[j].world_point) belongs to obj2:  $(b[j].shape ≈ csg.obj2)\tshape: $(typeof(b[j].shape)) ; obj2: $(typeof(csg.obj2))")
            if valid_hit(b[j], csg.obj1, csg)
                # debug: println("- $(b[j].world_point) is inside $(typeof(csg.obj1)):  ", is_inside(b[j], csg.obj1))
                push!(result, b[j])
                # debug: println("PUSHED: b[$j] = $(b[j].world_point)")
            end
            j += 1
        end
    end

    # check remaining elements
    while i <= length(a)
        # debug: println("-- $(a[i].world_point) belongs to obj1:  $(a[i].shape ≈ csg.obj1)\tshape: $(typeof(a[i].shape)) ; obj1: $(typeof(csg.obj1))")
        if valid_hit(a[i], csg.obj2, csg)
            # debug: println("- $(a[i].world_point) is inside $(typeof(csg.obj2)):  ", is_inside(a[i], csg.obj2))
            push!(result, a[i])
            # debug: println("PUSHED: a[$i] = $(a[i].world_point)")
        end
        i += 1
    end
    while j <= length(b)
        # debug: println("-- $(b[j].world_point) belongs to obj2:  $(b[j].shape ≈ csg.obj2)\tshape: $(typeof(b[j].shape)) ; obj2: $(typeof(csg.obj2))")
        if valid_hit(b[j], csg.obj1, csg)
            # debug: println("- $(b[j].world_point) is inside $(typeof(csg.obj1)):  ", is_inside(b[j], csg.obj1))
            push!(result, b[j])
            # debug: println("PUSHED: b[$j] = $(b[j].world_point)")
        end
        j += 1
    end

    return result
end

"""
Checks if a `Ray` intersects the `Csg`.
Return a sorted list of all `HitRecord`s or a list of `nothing` if no intersection is found.
"""
function ray_intersection(csg::Csg, ray::Ray; all=false)

    hit_array_1 = ray_intersection(csg.obj1, ray; all = true)
    # debug: println("\n::::::::::\n",hit_array_1)
    hit_array_2 = ray_intersection(csg.obj2, ray; all = true)
    # debug: println("\n::::::::::\n",hit_array_2)
    real_hits_1 = [h for h in hit_array_1 if h !== nothing]
    real_hits_2 = [h for h in hit_array_2 if h !== nothing]

    if (!isempty(real_hits_1) && !isempty(real_hits_2))
        hit_list = check_sort_records(real_hits_1, real_hits_2, csg)
        # debug: println("chosen:")
        for hit in hit_list
            # debug: println(hit.world_point)
        end
        if length(hit_list)==0
            return all ? [nothing] : nothing
        end
    else
        return all ? [nothing] : nothing
    end
    
    return all ? hit_list : hit_list[1]
    
end