# ─────────────────────────────────────────────────────────────
# World definition and functions
# ─────────────────────────────────────────────────────────────
"""
A collection of shapes forming a 3D world.

This struct has a field that is a vector of shapes (`shapes::Vector{Shape}`). 
    
It is possible to add shapes (`add!`) 
and check for intersections with a ray (`ray_intersection`).
"""
mutable struct World
    shapes::Vector{Shape{<:AbstractFloat}}
end

"""
Construct an empty world with no shapes.

This creates a new `World` with an empty list of shapes, allowing shapes
to be added later using the `add!` function.
"""
function World()
    World(Shape[])
end

"""
Add a shape to the world.

Appends the given `shape` to the `shapes` vector in the `world`.
"""
function add!(world::World, shape::Shape)
    push!(world.shapes, shape)
end

"""
Find the closest intersection between a ray and the shapes in the world.

Iterates over all shapes in the world, checking for intersections 
with the provided `ray` using the `ray_intersection` method.

Returns the closest intersection (`HitRecord`), if any, or `nothing` if no intersection is found.
"""
function ray_intersection(world::World, ray::Ray)
    closest = nothing
    for shape in world.shapes
        intersection = ray_intersection(shape, ray)
        if !isnothing(intersection) && (isnothing(closest) || intersection.t < closest.t)
            closest = intersection
        end
    end
    return closest
end